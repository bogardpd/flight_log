# Provides utilities for extracting Apple Wallet {PKPass} data from email
# attachments. This allows users to forward their digital boarding passes to a
# specified email address and have them show up as new {Flight Flights} they
# can {FlightsController#new add} with prepopulated form fields.
#
# PKPass boarding passes are a compressed folder containing a JSON file, which
# itself includes {BoardingPass} barcode data in IATA Bar Coded Boarding Pass
# (BCBP) format, along with some other metadata that can be used to prepopulate
# the {Flight} form fields.
# 
# @see PKPass
# @see https://developer.apple.com/documentation/passkit/wallet Wallet | Apple Developer Documentation
# @see https://www.iata.org/whatwedo/stb/Documents/BCBP-Implementation-Guide-5th-Edition-June-2016.pdf
#   IATA Bar Coded Boarding Pass (BCBP) Implementation Guide
module BoardingPassEmail
  
  # The content type string of an Apple Wallet PKPass file. Used to filter
  # email attachments.
  TYPE_PKPASS = "application/vnd.apple.pkpass"
  # The filename of the boarding pass JSON data within the PKPass compressed
  # folder.
  FILENAME_PASS = "pass.json"
  
  require "net/imap"
  require "mail"
  require "zip"
  
  include SessionsHelper
  
  # Accepts a list of email addresses, and process attachments from those
  # senders. Also deletes old emails.

  # Processes emails with boarding pass attachments sent from specified email
  # addresses.
  #
  # Once boarding pass data has been extracted from an email message's
  # attachment and saved into a {PKPass} object, the email message itself is
  # deleted.
  #
  # @param valid_emails [Array<String>] email addresses to search for
  #   attachments from
  # @return [Array<String>] JSON data contained within each PKPass attachment
  def self.process_attachments(valid_emails)
    imap = Net::IMAP.new("imap.gmail.com",993,true)
    imap.login(ENV["BOARDING_PASS_IMPORT_EMAIL_ADDRESS"],ENV["BOARDING_PASS_IMPORT_EMAIL_PASSWORD"])
    imap.select("INBOX")
    
    delete_old_emails(imap)
    
    if valid_emails.length == 0
      return nil
    elsif valid_emails.length == 1
      emails_from_user = imap.uid_search("FROM #{valid_emails[0]}")
    else
      emails_from_user = imap.uid_search("OR FROM #{valid_emails[0]} FROM #{valid_emails[1]}")
    end
    passes = emails_from_user.map{|uid| process_message(imap, uid)}
    
    imap.logout
    
    return passes.compact.flatten(1)
  end
  
  private
    
  # Deletes emails over 2 weeks old.
  # 
  # @return [Array<Integer>] IMAP UIDs of emails that were deleted
  def self.delete_old_emails(imap)
    old = imap.uid_search(["BEFORE", 2.weeks.ago.strftime("%d-%b-%Y")])
    if old.any?
      imap.uid_store(old, "+FLAGS", [:deleted])
      imap.expunge()
    end
    return old
  end

  
  # Accepts an IMAP connection and UID, finds any PKPass attachments, and
  # stores them in a database table. Deletes the email if it has no PKPass
  # attachments, or if the database store was successful. Returns an array of JSON strings or nil.
  # 
  # @param imap [Net::IMAP] an IMAP connection
  # @param uid [Integer] a message UID
  # @return [Array<String>] JSON data contained within each PKPass attachment
  def self.process_message(imap, uid)
    no_pkpass = Proc.new {|imap, uid|
      imap.uid_store(uid, "+FLAGS", [:deleted])
      return nil
    }
    
    message_received = imap.uid_fetch(uid, "ENVELOPE").first.dig("attr", "ENVELOPE", "date")
    message_datetime = message_received.present? ? Time.parse(message_received).utc : nil
    
    body = Mail.new(imap.uid_fetch(uid, "RFC822").first.attr["RFC822"])
    no_pkpass.call(imap, uid) unless body.attachments.present? # Email has no attachments
    
    pkpasses = body.attachments.select{|attachment| attachment.content_type.start_with?(TYPE_PKPASS)}
    no_pkpass.call(imap, uid) unless pkpasses.any? # None of the attachments are type .pkpass
  
    pass_data = extract_passes(pkpasses)
    pass_data.each do |pass|
      new_pass = PKPass.new(pass_json: pass, received: message_datetime)
      
      success = new_pass.save
      
      imap.uid_store(uid, "+FLAGS", [:deleted]) if success
    end
    
    return pass_data
  end
  
  # Extracts JSON data from PKPass attachments.
  # 
  # @param attachments [Array<Mail.body.attachment>] the attachments to parse
  # @return [Array<String>] JSON data contained within each PKPass attachment
  def self.extract_passes(attachments)
    output = nil
    Dir.mktmpdir{|dir|
      output = attachments.map.with_index{|attachment, index|
        File.open("#{dir}/#{index}.zip", "wb") do |file|
          file.write(attachment.body.decoded)
          Zip::File.open(file.path) do |zip_file|
            if zip_file.glob(FILENAME_PASS).any?
              pass = zip_file.glob(FILENAME_PASS).first.get_input_stream.read.force_encoding("UTF-8")
            end
          end   
        end
      }
    }
    return output
  end
  
end