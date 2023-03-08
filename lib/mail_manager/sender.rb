=begin
  
  class Sender
  ----------------
  Gestion de l'envoi du mail

=end
module MailManager
class Sender

attr_reader :mail

# @param [MailManager::Mail] L'instance du mail à envoyer
def initialize(mail)
  @mail = mail
end

# Pour envoyer le mail tout de suite
def send
  puts "Je dois apprendre à envoyer le mail tout de suite.".jaune
end

# Pour envoyer le mail plus tard
def send_later
  puts "Je dois apprendre à envoyer le mail plus tard.".jaune
end


# @return [Boolean] True s'il faut envoyer le mail tout de suite
def send_now?
  false # TODO
end



end #/class Sender
end #/module MailManager
