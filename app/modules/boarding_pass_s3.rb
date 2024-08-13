# Provides utilities for extracting Apple Wallet {PKPass} data from email
# attachments saved to an AWS S3 bucket. This allows users to forward their
# digital boarding passes to a specified email address (which are saved to an S3
# bucket with AWS SES) and have them show up as new {Flight Flights} they
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
module BoardingPassS3

  AWS_REGION = "us-east-2"
  AWS_S3_BUCKET = "flighthistorian-com-private"
  AWS_S3_PREFIX = "boarding-passes/"
  TYPE_PKPASS = "application/vnd.apple.pkpass"
  FILENAME_PASS = "pass.json"

  require "zip"

  # Fetches emails stored in the Flight Historian boarding pass AWS S3 bucket,
  # processes any PKPass attachments and stores them as {PKPass} objects, and
  # deletes the processed emails.
  def self.fetch_passes()
    return nil if Rails.env.test?
    Aws.config.update({
      credentials: Aws::Credentials.new(Rails.application.credentials[:aws][:write][:access_key_id], Rails.application.credentials[:aws][:write][:secret_access_key]),
      region: AWS_REGION
    })
    client = Aws::S3::Client.new

    s3_keys = s3_keys(client)
    for s3_key in s3_keys do
      process_email_message(client, s3_key)
    end

    return nil

  end

  private

  # Gets a list of keys for all objects within the AWS S3 boarding pass folder.
  #
  # @param client [Aws::S3:Client] an AWS S3 client
  # @return [Array<String>] AWS S3 keys
  def self.s3_keys(client)
    s3_keys = Array.new()
    resp = client.list_objects_v2({bucket: AWS_S3_BUCKET, prefix: AWS_S3_PREFIX})
    s3_keys.push(*resp[:contents].map{|r| r[:key]})
    while resp.next_page? do
      resp = resp.next_page
      s3_keys.push(*resp[:contents].map{|r| r[:key]})
    end
    s3_keys = s3_keys.select{|sk| sk != AWS_S3_PREFIX} # Exclude the folder itself
    return s3_keys
  end

  # Opens an email in S3, checks for PKPass attachments, saves them as PKPass
  # objects, and deletes the email.
  def self.process_email_message(client, s3_key)
    object = client.get_object(bucket: AWS_S3_BUCKET, key: s3_key)
    
    begin
      message = Mail.read_from_string(object.body.read())
    rescue ArgumentError
      client.delete_object(bucket: AWS_S3_BUCKET, key: s3_key)
      return
    end
    
    delete_object = true
    message_datetime = message.date.present? ? message.date.utc : nil
    for attachment in message.attachments do
      if attachment.content_type.start_with?(TYPE_PKPASS)
        pass_data = extract_pass(attachment)
        unless pass_data.nil?
          new_pass = PKPass.new(pass_json: pass_data, received: message_datetime)
          success = new_pass.save
          delete_object = false unless success
        end
      end
    end
    
    if delete_object
      client.delete_object(bucket: AWS_S3_BUCKET, key: s3_key)
    end
  end

  # Extracts JSON data from a PKPass attachment.
  #
  # @param attachment [Mail::Attachment] a PKPass email attachment
  # @return <String> JSON data contained within the PKPass attachment
  def self.extract_pass(attachment)
    output = nil
    Dir.mktmpdir{|dir|
      File.open("#{dir}/pass.zip", "wb") do |file|
        file.write(attachment.body.decoded)
        Zip::File.open(file.path) do |zip_file|
          if zip_file.glob(FILENAME_PASS).any?
            output = zip_file.glob(FILENAME_PASS).first.get_input_stream.read.force_encoding("UTF-8")
          end
        end
      end
    }
    return output
  end

end