module MailManager
class History
class << self

  ##
  # Méthode pour ajouter une "ligne d'historique"
  # @param [Symbol] type  Le type de log. :send est le plus fréquent et concerne les envois de messages
  # @param [Hash]   data  Les données utiles, en fonction du type
  def add(type, data)
    send("add_#{type}".to_sym, data)
  end

  ##
  # Réinitialisation du dossier courant
  def reset
    FileUtils.rm_rf(folder)
  end

  ##
  # Ré-initialise vraiment tout, en détruisant le fichier log
  def reset_all
    File.delete(log_path) if File.exist?(log_path)
    reset
  end

  ##
  # Sous-méthode d'ajout d'un envoi
  # 
  # @param [Hash] data Les données 
  # @option data [Mail]       :mail       Instance du mail
  # @option data [String]     :code_final Le code du mail envoyé
  # @option data [String]     :sender     Le mail de l'expéditeur
  # @option data [Recipient]  :recipient  Instance du destinataire
  # 
  def add_send(data)
    source = data[:mail].source
    recipient = data[:recipient]
    log("Envoi du message “#{source.name}” à #{recipient.inspect}")
    fname = "#{Time.now.strftime('%Y-%m-%d-%H_%M')}-#{recipient.mail}.eml"
    fpath = File.join(folder_mails, fname)
    File.write(fpath, data[:code_final])
  end

  def log(msg)
    msg = "--- [#{Time.now}] #{msg}\n"
    File.append(log_path, msg)
  end

  def log_path
    @log_path ||= begin
      File.join(TMP_FOLDER,'history.log')
    end
  end

  def folder_mails
    @folder_mails ||= mkdir(File.join(folder,'mails'))
  end
  def folder
    @folder ||= mkdir(File.join(TMP_FOLDER,'history'))
  end
end #/<< self
end #/class History
end # module MailManager
