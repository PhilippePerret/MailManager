=begin
  
  class Sender
  ----------------
  Gestion de l'envoi du mail

=end
require 'net/smtp'
module MailManager
class Sender

attr_reader :mail
attr_reader :source_file

# @param [MailManager::Mail] L'instance du mail à envoyer
def initialize(mail, source_file)
  @mail = mail
  @source_file = source_file
end

# Pour envoyer le mail tout de suite
def send
  require 'mail'

  # 
  # Expéditeur du message (le 'from' des métadonnées du fichier)
  # 
  sender_mail = source_file.sender[:mail].freeze

  # 
  # Boucle sur chaque destinataire
  # 
  source_file.destinataires.each do |destinataire|
    # +destinataire+ est une instance MailManager::Recipient
    code_final = code_mail_final(destinataire)
    Net::SMTP.start(*SERVER_DATA) do |smtp|
      smtp.send_message(
        code_final,
        sender_mail,
        destinataire.mail
      )
    end
  end

end #/send

# Pour envoyer le mail plus tard
def send_later
  puts "Je dois apprendre à envoyer le mail plus tard.".jaune
end


# @return [String] Le code final du mail, prêt à l'envoi
def code_mail_final(recipient)
  template % {
    destinataire: recipient.as_to,
    message:      source_file.message
  }
end

# @return [String] Le template du mail
# 
# Sont à remplacer :
#   :message        Le message finalisé
#   :destinataire   Le destinataire
# 
def template
  @template ||= mail.code_template_mail
end

# @return [Boolean] True s'il faut envoyer le mail tout de suite
def send_now?
  false # TODO
end

end #/class Sender
end #/module MailManager
