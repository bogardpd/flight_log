module BoardingPassEmail
  
  def self.process_attachments
    begin
      require 'net/imap'
      require 'mail'
      imap = Net::IMAP.new('imap.gmail.com',993,true)
      imap.login(ENV['BOARDING_PASS_IMPORT_EMAIL_ADDRESS'],ENV['BOARDING_PASS_IMPORT_EMAIL_PASSWORD'])
      imap.select('INBOX')
      all_mail    = imap.uid_search('ALL')
      bodies      = imap.uid_fetch(all_mail, 'RFC822').map{|m| Mail.new(m.attr['RFC822'])}
      attachments = bodies.select{|body| body.attachments.present?}.map{|body| body.attachments}.flatten
      
      output = attachments.map{|attachment| attachment.filename}
      
      #attachments.map.with_index{|attachment, index|
      #  Dir.mkdir(File.join("tmp/attachments", "#{index}"), 0700) unless File.exists("tmp/attachments/#{index}")
      #  File.open("tmp/attachments/#{index}/#{attachment.filename}", 'wb') do |file|
      #    file.write(attachment.body.decoded)
      #  end
      #}
      
      imap.logout
    rescue
      output = nil
    end
    return output
  end
  
end