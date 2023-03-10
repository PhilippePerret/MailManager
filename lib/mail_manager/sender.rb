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

  #
  # Demander confirmation, s'il y a plus d'un certain nombre
  # de destinataires
  # 
  count_recipients = source_file.destinataires.count
  if count_recipients > 5
    Q.yes?("Dois-je procéder à ce mailing (#{count_recipients} destinataires) ?".jaune) || begin
      puts "Bien, je renonce.".bleu
      return
    end
  end

  # 
  # Expéditeur du message (le 'from' des métadonnées du fichier)
  # 
  sender_mail = source_file.sender[:mail].freeze

  # 
  # Pour une simple simulation
  # 
  if simulation?
    puts "*** SIMPLE SIMULATION DE L'ENVOI ***".bleu
    del = '-'*80
  end

  # 
  # Boucle sur chaque destinataire
  # 
  source_file.destinataires.each do |destinataire|
    # +destinataire+ est une instance MailManager::Recipient
    code_final = code_mail_final(destinataire)
    if simulation?
      puts "\nMail à envoyer à #{destinataire.mail}"
      puts "#{del}\n#{code_final}\n#{del}"
    else
      Net::SMTP.start(*SERVER_DATA) do |smtp|
        smtp.send_message(
          code_final,
          sender_mail,
          destinataire.mail
        )
      end
      # 
      # Temporisation
      # 
      sleep 10 + rand(10)
    end
  end

end #/send

# Pour envoyer le mail plus tard
def send_later
  puts "Je dois apprendre à envoyer le mail plus tard.".jaune
end


# @return [String] Le code final du mail, prêt à l'envoi
def code_mail_final(recipient)
  data_template = {
    destinataire: recipient.as_to,
    message:      source_file.message
  }
  cmail = template  % data_template

  if cmail.match?(/\%\{/)
    data_template = recipient.as_hash.merge(FEMININES[recipient.sexe])
    cmail = cmail % data_template
  end
  return cmail
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

# --- Predicate Methods ---

# @return [Boolean] True s'il faut envoyer le mail tout de suite
def send_now?
  true # TODO
end

def simulation?
  :TRUE == @forsim ||= true_or_false(CLI.option(:simulation))
end

end #/class Sender
end #/module MailManager
