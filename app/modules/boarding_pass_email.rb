module BoardingPassEmail
  
  TYPE_PKPASS = "application/vnd.apple.pkpass"
  FILENAME_PASS = "pass.json"
  
  require 'net/imap'
  require 'mail'
  require 'zip'
  
  include SessionsHelper
  
  # Accepts a list of email addresses, and process attachments from those
  # senders. Also deletes old emails.
  def self.process_attachments(valid_emails)
    imap = Net::IMAP.new('imap.gmail.com',993,true)
    imap.login(ENV['BOARDING_PASS_IMPORT_EMAIL_ADDRESS'],ENV['BOARDING_PASS_IMPORT_EMAIL_PASSWORD'])
    imap.select('INBOX')
    
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
    
    # Deletes emails over 2 weeks old
    def self.delete_old_emails(imap)
      old = imap.uid_search(["BEFORE", 2.weeks.ago.strftime("%d-%b-%Y")])
      if old.any?
        imap.uid_store(old, "+FLAGS", [:deleted])
        imap.expunge()
      end
      return old
    end

    
    # Accepts an imap and UID, finds any pkpass attachments and stores them in a
    # database table. Deletes the email if no pkpass attachments or if database
    # store was successful. Returns an array of JSON strings or nil.
    def self.process_message(imap, uid)
      no_pkpass = Proc.new {|imap, uid|
        imap.uid_store(uid, "+FLAGS", [:deleted])
        return nil
      }
      
      message_received = imap.uid_fetch(uid, 'ENVELOPE').first.dig('attr', 'ENVELOPE', 'date')
      message_datetime = message_received.present? ? Time.parse(message_received).utc : nil
      
      body = Mail.new(imap.uid_fetch(uid, 'RFC822').first.attr['RFC822'])
      no_pkpass.call(imap, uid) unless body.attachments.present? # Email has no attachments
      
      pkpasses = body.attachments.select{|attachment| attachment.content_type.start_with?(TYPE_PKPASS)}
      no_pkpass.call(imap, uid) unless pkpasses.any? # None of the attachments are type .pkpass
   
      pass_data = extract_passes(pkpasses)
      pass_data.each do |pass|
        new_pass = PKPass.new(pass_json: pass, received: message_datetime)
        existing_record = PKPass.where(:serial_number => new_pass.serial_number).first
        if existing_record.present?
          if new_pass.received > existing_record.received
            success = existing_record.update_attributes(:pass_json => new_pass.pass_json, :serial_number => new_pass.serial_number, :received => new_pass.received)
          else
            success = true
          end
        else
          success = new_pass.save
        end
        imap.uid_store(uid, "+FLAGS", [:deleted]) if success
      end
      
      return pass_data
    end
    
    # Accepts an array of pkpass attachments and returns an array of pass.json data
    def self.extract_passes(attachments)
      output = nil
      Dir.mktmpdir{|dir|
        output = attachments.map.with_index{|attachment, index|
          File.open("#{dir}/#{index}.zip", 'wb') do |file|
            file.write(attachment.body.decoded)
            Zip::File.open(file.path) do |zip_file|
              if zip_file.glob(FILENAME_PASS).any?
                pass = zip_file.glob(FILENAME_PASS).first.get_input_stream.read.force_encoding('UTF-8')
              end
            end   
          end
        }
      }
      return output
    end
  
end