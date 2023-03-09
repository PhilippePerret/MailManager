=begin

  Module pour gérer les images dans un mail, pour le mettre en dur

=end
require 'base64'

module MailManager
class ImageManager
class << self
  
  # @return [HTMLString] le code "<img…>" pour insérer l'image
  # en dur dans le code HTML (d'un mail par exemple)
  def code_image(img_path, legende)
    image = new(img_path, legende)
    return image.code_image
  end

end #/<< self

###################       INSTANCE      ###################
  
  attr_reader :path, :alt
  def initialize(img_path, legende)
    @path = img_path
    @alt  = legende || File.basename(img_path)
  end

  def code_image
    CODE_IMAGE_TEMPLATE % {
      alt:    alt,
      format: format, # 'png', 'jpg', etc.
      code64: code64
    }
  end

  def format; File.extname(path)[1..-1] end
  def code64
    File.open(path,'rb'){|img| Base64.strict_encode64(img.read)}
  end


CODE_IMAGE_TEMPLATE = '<img src="data:image/%{format};base64,%{code64}" alt="%{alt}">'.freeze
end #/class ImageManager
end #/module MailManager
