require 'yaml'
require 'clir'
require "mail_manager/version"
require 'mail_manager/constants'
require "mail_manager/messages"
require "mail_manager/source_file"
require "mail_manager/mail"
require "mail_manager/sender"

module MailManager
  class Error < StandardError; end

  # = main =
  # 
  # Méthode principale pour envoyer un mail
  # 
  def self.send(path, **options)
    path_valid?(path) || return
    source = MailManager::SourceFile.new(path)
    mail   = MailManager::Mail.new(source)
    sender = MailManager::Sender.new(mail)
    if sender.send_now?
      sender.send 
    else
      sender.send_later
    end
    return true
  end


  # @return true si le chemin d'accès au fichier définissant le
  # mail (SourceFile) est valide. C'est-à-dire s'il existe et qu'il
  # porte l'extension Markdown (.md)
  def self.path_valid?(path)
    File.extname(path) == '.md' || raise('bad_extension')
    File.exist?(path) || raise('unfound_mail_file')
    return true
  rescue Exception => e
    msg = ERRORS[e.message.to_sym] % path
    puts msg.rouge
    return false
  end

end
