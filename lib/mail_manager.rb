require 'yaml'
require 'clir'
require "mail_manager/version"
require 'mail_manager/constants'
require "mail_manager/messages"

module MailManager
  class Error < StandardError; end
  def self.send(path, **options)
    path_valid?(path) || return
  end


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
