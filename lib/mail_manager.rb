require 'yaml'
require 'clir'
require_relative "mail_manager/version"
require_relative 'mail_manager/constants'
require_relative "mail_manager/messages_and_errors"
require_relative "mail_manager/csv"
require_relative "mail_manager/source_file"
require_relative "mail_manager/recipient"
require_relative "mail_manager/image_manager"
require_relative "mail_manager/message"
require_relative "mail_manager/mail"
require_relative "mail_manager/sender"
require_relative "mail_manager/reporter"
require_relative "mail_manager/history"
require_relative "mail_manager/utils"
require_relative "mail_manager/api"

module MailManager
  class Error < StandardError; end

  # = main =
  # 
  # Méthode principale pour envoyer un mail à partir d'un
  # fichier markdown à entête métadonnées.
  # 
  def self.send(path, **options)
    path = path_valid?(path) || return
    source = MailManager::SourceFile.new(path)
    if source.mail_type?
      require_relative 'mail_manager/source_file_mail_type'
      source = MailManager::SourceFileMailType.new(path)
    end
    mail   = MailManager::Mail.new(source)
    sender = MailManager::Sender.new(mail, source)
    if sender.send_now?
      sender.send 
    else
      sender.send_later
    end
    return true
  rescue BadListingError => e
    erreur(e)
  rescue InvalidDataError => e
    erreur(e)
  rescue MailManagerError => e
    erreur(e)
  end


  # @return true si le chemin d'accès au fichier définissant le
  # mail (SourceFile) est valide. C'est-à-dire s'il existe et qu'il
  # porte l'extension Markdown (.md)
  def self.path_valid?(path)
    path.nil? && raise('is_nil')
    # 
    # Si la valeur donnée ne contient pas .md, on ajoute cette
    # extensions
    # 
    path = "#{path}.md" if File.extname(path) == ''
    File.extname(path) == '.md' || raise('bad_extension')
    File.exist?(path) || raise('unfound_mail_file')
  rescue Exception => e
    msg = ERRORS['source_file'][e.message] % path
    puts msg.rouge
    return false
  else
    return path
  end

end
