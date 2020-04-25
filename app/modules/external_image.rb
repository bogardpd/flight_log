# Provides utilities for dealing with images hosted on an image storage service.
module ExternalImage
  
  # The root URL for this application's external images.
  ROOT_PATH = "https://pbogardcom-images.s3.us-east-2.amazonaws.com/"
  
  # Returns the URL for an external image.
  #
  # @param relative_path [String] the relative path on the external image server
  # @return [String] the file's absolute path
  def self.url(relative_path)
    return [ROOT_PATH, relative_path].join()
  end

  # Checks if an image exists.
  # 
  # Note that this method checks an absolute path, so {ROOT_PATH} is not
  # automatically prepended. Be sure to manually include {ROOT_PATH} in the path
  # string if the image is hosted there.
  #
  # @param path [String] the absolute path to check
  # @return [Boolean] true if the image at path exists, false otherwise
  def self.exists?(path)
    require "net/http"
    url = URI.parse(path)
    req = Net::HTTP.new(url.host)
    res = req.request_head(url.path)
    return (res.code.to_i == 200)
  rescue SocketError
    return false
  end
  
end