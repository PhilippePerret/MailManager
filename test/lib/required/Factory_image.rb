require 'base64'

class Factory
class Image
class << self

  def base64(image_path)
    File.open(image_path,'rb'){|img| Base64.strict_encode64(img.read)}
  end

end #/<< self
end #/class Image
end #/class Factory
