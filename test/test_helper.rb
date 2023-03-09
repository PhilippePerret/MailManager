$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "mail_manager"

require_relative 'lib/factory'
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
