module MailManager

  LANG   = 'fr'
  ERRORS = YAML.load_file("#{GEM_LIB_FOLDER}/locales/#{LANG}/errors.yaml")

  class MailManagerError < StandardError; end
  class InvalidDataError < StandardError; end
  class BadListingError < StandardError; end


  def self.erreur(err)
    puts "#{err.class} : #{err.message}".rouge
    puts err.backtrace.join("\n").rouge if debug?
  end
  
end
