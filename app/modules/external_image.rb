module ExternalImage
  
  ROOT_PATH = "https://s3.us-east-2.amazonaws.com/pbogardcom-images"
  
  # Returns true if the image at path exists, false otherwise.
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