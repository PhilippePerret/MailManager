=begin
  
  class Mail
  ----------------
  Gestion de l'envoi du mail

=end
module MailManager
class Mail

attr_reader :source

# @param [MailManager::SourceFile] L'instance du fichier source
def initialize(source)
  @source = source
end


end #/class Mail
end #/module MailManager
