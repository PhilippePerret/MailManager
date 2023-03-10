=begin
  Class MailManager::Report
  -------------------------
  Gestion du rapport d'envoi
=end
module MailManager
class Report

  attr_reader :sender

  # Instanciation
  # @param [MailManager::Sender] sender L'expéditeur de mail
  def initialize(sender)
    @sender = sender
    # 
    # Instanciations
    # 
    @errors   = []
    @success  = []
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
    unless @errors.empty?
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
    if @errors.count == 0
      puts "Mailing successfull. Mails sent: #{@success.count}.".vert
    elsif @success.count == 0
      puts "Mailing fails… Zero mails sent…".rouge
    else
      # - Rapport mitigé -
      puts "Mails sent: #{@success.count} | Failures: #{@errors.count} ".orange
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


  def add_failure(recipient, err)
    @errors << {recipient: recipient, error: err, time: Time.now}
  end
  def add_success(recipient)
    @success << {recipient: recipient, time: Time.now}
  end


  # --- Predicate Methods ---

  def errors?
    @errors.count > 0
  end
end #/class Report
end #/module MailManage
