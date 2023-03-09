module MailManager

  GEM_LIB_FOLDER = File.expand_path(File.dirname(__dir__))
  GEM_FOLDER = File.dirname(GEM_LIB_FOLDER)

  require '/Users/philippeperret/.secret/mail'
  DSMTP = MAILS_DATA[:smtp]
  SERVER_DATA = [DSMTP[:server],DSMTP[:port],DSMTP[:domain],DSMTP[:user_name],DSMTP[:password],:login]

end #/module MailManager
