=begin
  
  class Sender
  ----------------
  Gestion de l'envoi du mail

=end
require 'net/smtp'
module MailManager
class Sender
###################       CLASSE      ###################
class << self
  def print_suivi
    if test?
      # 
      # En mode test, on enregistre le suivi dans un fichier
      #
      suivi_path = File.join(TMP_FOLDER,'suivi.log')
      File.write(suivi_path, suivi.join("\n"))
    else
      # 
      # En mode normal, on l'affiche à l'écran
      # 
      clear
      puts suivi.join("\n")
    end
    @suivi = nil
  end
  def suivi
    @suivi ||= ["\n","\n"]
  end
end #/<< self
###################       INSTANCE      ###################
  
attr_reader :mail
attr_reader :source_file

# @param [MailManager::Mail] L'instance du mail à envoyer
def initialize(mail, source_file)
  @mail = mail
  @source_file = source_file
end

# Pour envoyer le mail
def send

  #
  # Initialisation de l'historique pour cet envoi
  # 
  # @warning
  #   Cette méthode ne détruit pas le fichier tmp/history.log mais
  #   détruit le dossier contenant les mails envoyés précédemment.
  # 
  History.reset

  Sender.suivi << "--- Envoi du message « #{mail.name} » ---".bleu
  Sender.suivi << "(commence par « #{source_file.raw_message[0..200].gsub(/\n/, '⏎')}»)".gris
  Sender.print_suivi

  # 
  # Nombre de mails à envoyer
  # 
  # @note
  #   C'est ici que pour un mail-type, on demande les destinataires
  #   des messages
  # 
  begin
    Object.const_set('NOMBRE_MAILS', recipients.count)
  rescue TTY::Reader::InputInterrupt
    puts "\n\nAbandon…".bleu
    exit 3
  end

  # 
  # Nombre d'exclusions
  # 
  nombre_exclusions = MailManager::Recipient.exclusions.count

  #
  # Faut-il limiter le nombre d'envoi ? (options)
  # 
  nombre_mails_limite = nil
  if CLI.options.key?(:n)
    nombre_mails_limite = CLI.option(:n).to_i
  end

  #
  # Demander confirmation, s'il y a plus d'un certain nombre
  # de destinataires
  # 
  if nombre_mails_limite.nil? && NOMBRE_MAILS > 5
    text_nombre = ["#{NOMBRE_MAILS} destinataires"]
    text_nombre << " (#{nombre_exclusions} exclusions)" if nombre_exclusions > 0
    text_nombre = text_nombre.join('')
    Q.yes?("Dois-je procéder à #{'la simulation de ' if simulation?}ce mailing (#{text_nombre}) ?".jaune) || begin
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

    if nombre_mails_limite && (idx+1) > nombre_mails_limite
      puts "Nombre limite de mails atteint (#{nombre_mails_limite})".bleu
      break
    end
    
    # 
    # Fabrication du code final en fonction du destinataire
    # 
    begin
      code_final = code_mail_final(destinataire)
    rescue TTY::Reader::InputInterrupt
      puts "\n\nAbandon…".bleu
      exit 3
    rescue Exception => e
      reporter.add_failure(destinataire, source_file, e)      
      next
    end
    # 
    # Temporisation
    # 
    temporiser(idx, destinataire.mail) unless no_delai? || test?
    STDOUT.write "\rEnvoi du message…".ljust(console_width).bleu

    #
    # Quelle que soit la situation, on enregistre toujours ce
    # message dans le dossier temporaire
    # @note
    #   C'est la class History qui s'en charge
    # 
    History.add(:send, {mail:mail, code_final:code_final, sender:sender_mail, recipient:destinataire})

    if simulation?

      simule_envoi_mail(destinataire, code_final)
      reporter.add_success(destinataire, source_file)
    
    else

      #############################
      ###     ENVOI DU MAIL     ###
      #############################
      begin
        unless test?
          Net::SMTP.start(*SERVER_DATA) do |smtp|
            smtp.send_message(code_final,sender_mail,destinataire.mail)
          end
        end
      rescue TTY::Reader::InputInterrupt
        puts "\n\nAbandon…".bleu
        exit 3
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
    if Q.yes?('Dois-je ouvrir les messages masculins/féminins ?'.jaune)
      `open "#{mail_femme_path}"` if File.exist?(mail_femme_path)
      `open "#{mail_homme_path}"` if File.exist?(mail_homme_path)
    end
  end
end #/send


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
  MailManager::Recipient.final_recipients(self)
end

def reporter
  @reporter ||= Reporter.new(self)
end

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
  if CLI.option(:no_delay)
    sleep 1
  else
    secondes = delai_incompressible + rand(delai_compressible)
    nieme = idx > 0 ? "#{idx + 1}e" : '1er'
    prefix_sim = simulation? ? "[SIMULATION] " : ''
    while (secondes -= 1) > 0
      STDOUT.write "\r#{prefix_sim}Attente de #{secondes} secondes avant l'envoi du #{nieme} message sur #{NOMBRE_MAILS} (#{mail}).".ljust(console_width).jaune
      sleep 1
    end
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
