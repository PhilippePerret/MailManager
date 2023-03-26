$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "mail_manager"

Dir["#{__dir__}/lib/required/**/*.rb"].each{|m|require m}

# require_relative '../lib/mail_manager/messages'

ERRORS = MailManager::ERRORS

require "minitest/autorun"
require 'minitest/reporters'
reporter_options = { 
  color: true,          # pour utiliser les couleurs
  slow_threshold: true, # pour signaler les tests trop longs
}
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(reporter_options)]

TEST_FOLDER = __dir__
APP_FOLDER  = File.dirname(TEST_FOLDER)
TMP_FOLDER  = File.join(APP_FOLDER,'tmp')
MAIL_MARION = 'marion.michel31@free.fr'
MAIL_PHIL   = 'philippe.perret@yahoo.fr'

module Minitest
class Test

  # Test en réel l'envoi du message de chemin +path+
  # 
  # Les résultats sont déposés dans le dossier tmp/tests/ qui 
  # est vidé avant chaque appel (sauf si options[:keep] est true)
  # 
  def essai_send_mail(path, affixe_command = nil, options = nil)
    options ||= {}
    puts "Test de l'envoi du message #{path}".gris
    dossier = File.dirname(path)
    affixe  = File.basename(path,File.extname(path))
    affixe_command ||= affixe
    res = `cd "#{dossier}";send-mail #{affixe_command} -t`
    puts "res = #{res}"
  end


end #/class Minitest::Test
end
