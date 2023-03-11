=begin

  Module pour gérer les images dans un mail, 
  Et notamment pour les mettre en dur

=end
require 'base64'

module MailManager
class ImageManager
class << self

  def init
    @images = {}
  end

  ##
  # À l'analyse du fichier source, lorsque les métadonnées contiennent
  # une clé qui commence par IMG, elle est envoyée ici. Si cette clé
  # contient un '-', c'est une propriété d'image qui est définie. 
  # Sinon, c'est l'image elle-même
  def traite_metadata(key, val)
    if key.match?(/\-/)
      key_image, key_prop = key.split('-')
      @images[key_image].send("#{key_prop}=".to_sym, val)
    else
      @images.merge!(key => new(key, val))
    end
  end

  # Pour boucler sur toutes les images définies dans les
  # métadonnées
  def each &block
    @images.values.each do |image|
      yield image
    end
  end

end #/<< self

###################       INSTANCE      ###################
  
  attr_reader :key, :path

  # Les propriétés qu'on peut définir par <IMGkey>-<prop> dans
  # les métadonnées.
  attr_accessor :alt, :style, :width, :link

  def initialize(img_key, img_path)
    @key  = img_key
    @path = img_path
  end

  def to_html
    template % data_template
  end

  def data_template
    {
      alt:    alt,
      format: format, # 'png', 'jpg', etc.
      code64: code64,
      style:  style,
      width:  width,
      link:   link,
    }
  end

  # Le template à utiliser en fonction des propriétés définies
  def template
    @template ||= begin
      if link.nil?
        CODE_IMAGE_TEMPLATE
      else
        CODE_IMAGE_TEMPLATE_LINKED
      end
    end
  end

  def format; File.extname(path)[1..-1] end
  def code64
    File.open(path,'rb'){|img| Base64.strict_encode64(img.read)}
  end


CODE_IMAGE_TEMPLATE = '<img width="%{width}" style="%{style}" src="data:image/%{format};base64,%{code64}" alt="%{alt}">'.freeze

CODE_IMAGE_TEMPLATE_LINKED = ('<a href="%{link}">'+CODE_IMAGE_TEMPLATE+'</a>').freeze

end #/class ImageManager

ImageManager.init

end #/module MailManager
