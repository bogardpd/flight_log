module BoardingPassEmail
  
  TYPE_PKPASS = "application/vnd.apple.pkpass"
  FILENAME_PASS = "pass.json"
  
  require 'net/imap'
  require 'mail'
  require 'zip'
  
  def self.process_attachments
   
    imap = Net::IMAP.new('imap.gmail.com',993,true)
    # TODO: Login with token instead
    imap.login(ENV['BOARDING_PASS_IMPORT_EMAIL_ADDRESS'],ENV['BOARDING_PASS_IMPORT_EMAIL_PASSWORD'])
    imap.select('INBOX')
    
    passes = imap.uid_search('ALL').map{|uid| process_message(imap, uid)}
    
    imap.logout
    
    return passes.compact.flatten(1)
  end
  
  private
  
    # Accepts an imap and UID, finds any pkpass attachments and stores them in a
    # database table. Deletes the email if no pkpass attachments or if database
    # store was successful. Returns an array of JSON strings or nil.
    def self.process_message(imap, uid)
      no_pkpass = Proc.new {|imap, uid|
        imap.uid_store(uid, "+FLAGS", [:deleted])
        return nil
      }
      
      body = Mail.new(imap.uid_fetch(uid, 'RFC822').first.attr['RFC822'])
      no_pkpass.call(imap, uid) unless body.attachments.present? # Email has no attachments
      
      pkpasses = body.attachments.select{|attachment| attachment.content_type.start_with?(TYPE_PKPASS)}
      no_pkpass.call(imap, uid) unless pkpasses.any? # None of the attachments are type .pkpass
   
      pass_data = extract_passes(pkpasses)
      pass_data.each do |pass|
        # TODO: Check if pass already exists
        # TODO: Store in database (field serialize JSON)
      end
      # TODO: Delete email if store successful
      
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