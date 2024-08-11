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

    # Get array of keys for potential boarding pass objects.
    s3_keys = s3_keys(client)

    puts s3_keys

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

end