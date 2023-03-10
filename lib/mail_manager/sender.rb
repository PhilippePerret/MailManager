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

# DESTINATAIRES du mail
# 
# @return [Array<MailManager::Recipient>] La liste des destinataires
# 
# @note
#   C'est soit la liste défini dans le fichier du mail, soit, si
#   l'option -e/--mail_errors est activée, la liste des mails du
#   dernier envoi qui ont échoué
# 
def recipients
  @recipients ||= begin
    if CLI.option(:mail_errors)
      if File.exist?(reporter.errors_file)
        errors = Marshal.load(File.read(reporter.errors_file))
        File.delete(reporter.errors_file)
        errors.map { |derr| derr[:recipient] }
      else
        raise MailManagerError, ERRORS['no_mails_errors_file']
      end
    else
      source_file.destinataires
    end
  end
end

def reporter
  @reporter ||= Report.new(self)
end

# Pour envoyer le mail tout de suite
def send
  clear
  # 
  # Nombre de mails à envoyer
  # 
  Object.const_set('NOMBRE_MAILS', recipients.count)

  #
  # Demander confirmation, s'il y a plus d'un certain nombre
  # de destinataires
  # 
  if NOMBRE_MAILS > 5
    Q.yes?("Dois-je procéder à ce mailing (#{NOMBRE_MAILS} destinataires) ?".jaune) || begin
      puts "Bien, je renonce.".bleu
      return
    end
    # 
    # Ouvrir le log du rapporteur si on a plus de 5 mails
    # 
    reporter.open_log_file
  end

  # 
  # Expéditeur du message (le 'from' des métadonnées du fichier)
  # 
  sender_mail = source_file.sender[:mail].freeze

  # 
  # Pour une simple simulation
  # 
  reset_simulation if simulation?

  # 
  # BOUCLE SUR CHAQUE DESTINATAIRE
  # 
  recipients.each_with_index do |destinataire, idx|
    # +destinataire+ est une instance MailManager::Recipient
    
    # 
    # Fabrication du code final en fonction du destinataire
    # 
    code_final = code_mail_final(destinataire)
    # 
    # Temporisation
    # 
    temporiser(idx, destinataire.mail) unless no_delai?
    STDOUT.write "\rEnvoi du message…".ljust(console_width).bleu

    if simulation?
      simule_envoi_mail(destinataire, code_final)
    else

      #############################
      ###     ENVOI DU MAIL     ###
      #############################
      begin
        Net::SMTP.start(*SERVER_DATA) do |smtp|
          smtp.send_message(code_final,sender_mail,destinataire.mail)
        end
      rescue Exception => e
        reporter.add_failure(destinataire, source_file, e)
      else
        reporter.add_success(destinataire, source_file)
      end
    end
  end
  # 
  # Afficher le rapport final
  # 
  reporter.display_report

  # 
  # Ouverture des messages simulés
  # 
  if simulation?
    if Q.yes?('Dois-je ouvrir les messages masculins/féminins ?')
      `open "#{mail_femme_path}"` if File.exist?(mail_femme_path)
      `open "#{mail_homme_path}"` if File.exist?(mail_homme_path)
    end
  end
end #/send

def mail_femme_path
  @mail_femme_path ||= File.join(TMP_FOLDER,'mail_femme.eml')
end
def mail_homme_path
  @mail_homme_path ||= File.join(TMP_FOLDER,'mail_homme.eml')
end

# Méthode qui attend un nombre aléatoire de secondes avant d'envoyer
# le message.
# 
# @param [Integer] idx Indice du message (0-start)
# @param [String] mail Adresse mail en attente d'être envoyé
def temporiser(idx, mail)
  secondes = delai_incompressible + rand(delai_compressible)
  nieme = idx > 0 ? "#{idx + 1}e" : '1er'
  while (secondes -= 1) > 0
    STDOUT.write "\rAttente de #{secondes} secondes avant l'envoi du #{nieme} message sur #{NOMBRE_MAILS} (#{mail}).".ljust(console_width).jaune
    sleep 1
  end
end
def delai_incompressible
  @delai_incompressible ||= simulation? ? 2 : 4
end
def delai_compressible
  @delai_compressible ||= simulation? ? 10 : 26
end

def reset_simulation
  File.delete(mail_femme_path) if File.exist?(mail_femme_path)
  File.delete(mail_homme_path) if File.exist?(mail_homme_path)
  puts "*** SIMPLE SIMULATION DE L'ENVOI ***".bleu
end

def simule_envoi_mail(destinataire, code_final)
  # 
  # On enregistre le mail masculin et le mail féminin
  # 
  if destinataire.femme? && not(File.exist?(mail_femme_path))
    File.write(mail_femme_path, code_final)
  elsif destinataire.homme? && not(File.exist?(mail_homme_path))
    File.write(mail_homme_path, code_final)
  end
  puts "  -> 👻 Simulation d'envoi à #{destinataire.mail}".bleu
end

def no_delai?
  false
end


# @return [String] Le code final du mail, prêt à l'envoi
def code_mail_final(recipient)
  return mail.assemble_code_final(recipient)
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
