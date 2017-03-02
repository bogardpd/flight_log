module BoardingPassEmail
  
  TYPE_PKPASS = "application/vnd.apple.pkpass"
  
  def self.process_attachments
   
    #begin
      require 'net/imap'
      require 'mail'
      imap = Net::IMAP.new('imap.gmail.com',993,true)
      imap.login(ENV['BOARDING_PASS_IMPORT_EMAIL_ADDRESS'],ENV['BOARDING_PASS_IMPORT_EMAIL_PASSWORD'])
      imap.select('INBOX')
      all_mail = imap.uid_search('ALL')
      bodies   = imap.uid_fetch(all_mail, 'RFC822').map{|m| Mail.new(m.attr['RFC822'])}
      passes   = pkpass_attachments(bodies)
      passjson = extract_passes(passes)
      
      #output = passes.map{|attachment| attachment.content_type}
      output = passjson
      
      imap.logout
      #rescue
      #output = nil
      #end
    return output
  end
  
  private
    
    # Accepts an array of message bodies and returns all pkpass attachments
    def self.pkpass_attachments(bodies)
      attachments = bodies.select{|body| body.attachments.present?}.map{|body| body.attachments}.flatten
      pkpass_atch = attachments.select{|attachment| attachment.content_type.start_with?(TYPE_PKPASS)}
      return pkpass_atch
    end
    
    # Accepts an array of pkpass attachments and returns an array of pass.json data
    def self.extract_passes(attachments)
      output = nil
      Dir.mktmpdir{|dir|
        output = attachments.map.with_index{|attachment, index|
          File.open("#{dir}/#{index}.zip", 'wb') do |file|
            file.write(attachment.body.decoded)
            # TODO: Unzip and extract JSON
            file.path
          end
        }
      }
      return output
    end
  
end