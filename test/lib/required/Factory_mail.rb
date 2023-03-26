require 'date'

class Factory
class Mail
###################       CLASSE      ###################
class << self

  # liste [Array<Factory::Mail>] des derniers mails erronnés
  attr_reader :last_errors

  def has?(props)
    @last_errors = []
    candidats = all

    if candidats.empty?
      @last_errors << "Aucun mail n'a été envoyé…"
    end

    # 
    # Si les propriétés contiennent :email, on filtre déjà
    # par mail
    # 
    if props.key?(:to)
      expected = props.delete(:to)
      candidats = candidats.select do |mail|
        mail.to == expected
      end

      if candidats.empty?
        @last_errors << "Aucun mail n'a été envoyé à : #{expected}."
        return false
      end

    end
    if props.key?(:subject)
      expected = props.delete(:subject)
      candidats = candidats.select do |mail|
        mail.subject == expected
      end

      if candidats.empty?
        @last_errors << "Aucun mail retenu ne possède le sujet #{expected.inspect}"
        return false
      end
    end

    return false if candidats.empty?

    # puts "props = #{props.inspect}"
    # puts "candidats = #{candidats.count}"

    # @note
    #   Il ne reste plus de candidats, si c'est juste une
    #   recherche par mail et sujet.
    # 
    errors = []
    candidats.each do |mail|
      all_props_are_ok = mail.has?(props)
      if all_props_are_ok
        return true 
      else
        errors << mail
      end
    end
    
    @last_errors = errors
    return errors.empty?
  end

private

  # Retourne tous les mails envoyés sous forme d'instances Factory::Mail
  def all
    Dir["#{folder}/*.eml"].map { |mpath| new(mpath) }
  end

  def folder
    @folder ||= File.join(TMP_FOLDER,'history','mails')
  end

end #<< self
###################       INSTANCE      ###################
  public

  attr_reader :path

  attr_reader :errors

  def initialize(path)
    @path = path
    @errors = []
  end

  # --- Test du mail ---

  # Méthode appelée quand une donnée ne correspond (fatalement)
  def failure(prop, verbe, expected, actual)
    msg = if verbe == 'contenir'
      "Pour la propriété #{prop.inspect}, #{expected.inspect} devrait contenir #{actual.inspect}."
    else
      "La propriété #{prop.inspect} devrait #{verbe} #{expected.inspect}, elle vaut #{actual.inspect}."      
    end
    @errors << msg
    return false
  end

  # Pour formater l'erreur ou les erreurs
  def formate_errors
    "Mail « #{subject} » à #{to}\n#{errors}"
  end

  # @return true Si le mail contient toutes les +props+
  def has?(props)
    props.each do |prop, value|
      case prop
      when :content, :plain_content
        if not(plain_contains?(value))
          return failure(prop, "contenir", value, plain_content)
        end
      when :html_content
        if not(html_contains?(value))
          return failure(prop, "contenir", value, html_content)
        end
      when :mail
        return failure(prop, 'valoir', value, mail) if differ(mail, value)
      when :subject
        return failure(prop, 'valoir', value, subject) if differ(subject, value)
      when :after
        mail_value = date
        return failure('Date', 'être après', value, mail_value) if mail_value < value
      when :before
        mail_value = date
        return failure('Date', 'être avant', value, mail_value) if mail_value > value
      end
    end
    return true    
  end

  def differ(actual, expected)
    case expected
    when String, Integer
      return actual != expected
    when Regexp
      return not(actual.match?(expected))
    end
  end

  def plain_contains?(searches)
    return contains?(plain_content, searches)
  end

  def html_contains?(searches)
    return contains?(html_content, searches)
  end

  def contains?(content, searches)
    searches = [searches] unless searches.is_a?(Array)
    searches.each do |search|
      search = /#{search}/i unless search.is_a?(Regexp)
      return false unless content.match?(search)
    end
    return true
  end

  # --- Propriétés du mail ---

  def to
    @to ||= treate_as_email(getdata('To'))
  end

  def from
    @from ||= treate_as_email(getdata('From'))
  end

  def subject
    @subject ||= getdata('Subject')
  end

  def plain_content
    @content ||= parts['text/plain']
  end

  def html_content
    @html_content || parts['text/html']
  end

  def date
    @date ||= begin
      DateTime.parse(getdata('Date')).to_time
    end
  end

  def patronyme
    @patronyme || to # force l'analyse
    @patronyme
  end

  def boundary
    @boundary ||= raw_code.match(/boundary=\"(.+?)\"/)[1]
  end

  # --- Code ---

  def raw_code
    @raw_code = File.read(path)
  end

  # @return [Hash] Sections du code, découpé par frontière
  # En clé : le content-type (donc 'multipart/alternative', 'text/plain' et 'text/html')
  # En valeur : tout le code
  def parts
    @parts ||= mail_parts
  end

  private

    def getdata(dname)
      return raw_code.match(/^#{dname}:(.+)$/)[1].strip
    end
  

    def treate_as_email(email)
      return email unless email.match('<')  
      res = email.match(REG_MAIL_WITH_PATRO)
      @patronym = res[1].strip
      return res[2].strip
    end

    # Méthode qui récupère et retourne le contenu plain/text du
    # message
    def get_content
      
    end


    def mail_parts
      parts = {}
      raw_code.split("--#{boundary}").compact.map do |part|
        part = part.strip
        next if part == '--'
        content_type = part.match(/Content\-Type\:(.+?);/)[1].strip
        parts.merge!(content_type => part)
      end
      return parts
    rescue Exception => e
      # puts "Problème pour découper le code du mail :\n#{raw_code}".rouge
      puts "ERREUR : #{e.message}".rouge
      # puts "parts = #{parts.inspect}".orange
    end

REG_MAIL_WITH_PATRO = /^(.+?)<((?:.+?)@(?:.+?))>$/

end #/class Mail
end #/class Factory
