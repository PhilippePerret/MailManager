=begin
  Class MailManager::Report
  -------------------------
  Gestion du rapport d'envoi
=end
module MailManager
class Reporter

  attr_reader :sender

  # Instanciation
  # @param [MailManager::Sender] sender L'expéditeur de mail
  def initialize(sender)
    @sender = sender
    # 
    # Instanciations
    # 
    @errors     = []
    @success    = []
    @exclusions = []
  end

  def errors_file
    @errors_file ||= File.join(TMP_FOLDER,'SENDER_ERRORS')
  end

  # --- Helpers Methods ---

  # Méthode affichant le rapport final, après envoi des mails
  # 
  def display_report
    puts "\n\n"
    # 
    # Affichage des erreurs s'il y en a
    # 
    if errors?
      puts "ERRORS".rouge
      puts "------".rouge
      @errors.each do |derr|
        puts "  🧨 #{derr[:error].message} (#{derr[:recipient].mail}"
      end
      # 
      # On consigne les erreurs dans un fichier, au format Marshal
      # 
      File.open(errors_file,'wb') { |f| Marshal.dump(@errors, f) }
    end
    # 
    # Message de conclusion (succès ou échec ou les deux)
    # 
    puts "\n"
    if nombre_erreurs == 0
      puts "Mailing successfull. Mails sent: #{nombre_success}.".vert
    elsif nombre_success == 0
      puts "Mailing fails… Zero mails sent… (failures: #{nombre_erreurs})".rouge
    else
      # - Rapport mitigé -
      puts "Mails sent: #{nombre_success} | Failures: #{nombre_erreurs} ".orange
    end
    # 
    # Message indiquant comment traiter les mails échoués
    # 
    if errors?
      puts <<-TXT.bleu
      Les mails non envoyés ont été consignés.
      Pour leur envoyer à nouveau le message, corriger l'erreur et 
      jouer la commande 'send-mails' avec l'option -e.
      TXT
    end
  end

  def add_exclusion(recipient, source_file)
    @exclusions << {recipient:recipient, time: Time.now }
    log("📤 Exclus de l'envoi : #{recipient.inspect}")
  end

  def add_failure(recipient, source_file, err)
    @errors << {recipient: recipient, error: err, time: Time.now}
    log("🧨 Problème avec : #{recipient.mail} : #{err.message}")
  end

  def add_success(recipient, source_file)
    @success << {recipient: recipient, time: Time.now}
    log("Envoi à #{recipient.inspect} du mail #{source_file.subject}")
  end

  # --- Methodes de comptes ---

  def nombre_erreurs 
    @nombre_erreurs ||= @errors.count
  end

  def nombre_success 
    @nombre_success ||= @success.count
  end

  # --- Predicate Methods ---

  def errors?
    nombre_erreurs > 0
  end

  # --- Log Methods ---

  def log(msg, no_header = false)
    msg = "--- #{Time.now.strftime('%H:%M:%S')} #{msg}" unless no_header
    File.open(logfile,'a') do |f|
      f.puts msg
    end
  end

  def open_log_file
    File.delete(logfile) if File.exist?(logfile)
    log("--- DÉBUT D'ENVOI : #{Time.now} ---", true)
    `open "#{logfile}"`
  end

  def logfile
    @logfile ||= File.join(TMP_FOLDER,'envoi.log')
  end
end #/class Report
end #/module MailManage
