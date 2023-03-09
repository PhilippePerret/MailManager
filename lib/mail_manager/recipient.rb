=begin
  
  class MailManager::Recipient
  ----------------------------
  Gestion des destinataires

=end
module MailManager
class Recipient

###################       CLASSE      ###################
class << self

# @return [Array<MailManager::Recipient>] La liste des
# destinataires, même lorsqu'il n'y en a qu'un seul.
def destinataires_from(str, **options)
  if File.exist?(str)
    # <= Un fichier
    # => C'est une liste de destinataires

  elsif str.match?('@')
    # <= Contient l'arobase
    # => C'est une adresse mail
    [new(str)]
  end
end

end #/<< self
###################       INSTANCE      ###################
  
  attr_reader :mail


  BASE_REG_MAIL = /((?:[a-zA-Z0-9._\-]+)@(?:[^ .]+)\..{2,10})/
  REG_MAIL = /^#{BASE_REG_MAIL}$/
  REG_MAIL_AND_PATRO = /^(.+?)<#{BASE_REG_MAIL}>$/

  # Instanciation d'un destinataire.
  # Peut être instancié par :
  #   - un string : l'adresse mail seule
  #   - un string : une ligne de donnée d'un fichier csv
  #   - un hash : les données :mail, :patronyme, etc.
  def initialize(designation)
    case designation
    when REG_MAIL_AND_PATRO
      dre = designation.match(REG_MAIL_AND_PATRO)
      @mail = dre[2].strip
      @patronyme = dre[1].strip
    when REG_MAIL
      @mail       = designation
      @patronyme  = nil
    when String
      raise ERRORS['mail']['invalid'] % designation
    when Hash
      dispatch_data(designation)
    end  
  end


  # @return [String] L'adresse à écrire dans le mail
  def as_to
    str = mail
    str = "#{patronyme} <#{mail}>" if patronyme
    return str
  end

  def patronyme
    @patronyme ||= nil
  end


private

  def dispatch_data(data)
    data.each do |k, v|
      self.instance_variable_set("@#{k}", v)
    end
  end
end #/class Recipient
end #/module MailManager
