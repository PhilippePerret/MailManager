=begin
  Module permettant de tester les exclusions

  Pour le lancer :

    rake test TEST=test/exclusions_test.rb

=end
require 'test_helper'
class ExclusionsTest < Minitest::Test

  def setup
    super
  end

  def teardown
    super
  end

  # @live
  # 
  def test_ne_traite_pas_les_exclus
    # Ce test permet de vérifier que les exclus ne reçoivent pas
    # les mails
    # 
    now = Time.now.freeze
    sleep 1
    # ===> Test <===
    source = Factory.source_file({name: 'with_exclusions'})
    essai_send_mail(source.path)
    # --- Vérification ---
    assert_mail_received_by(MAIL_MARION, {
      subject:"Envoi avec des exclusions",
      after: now,
      content: "Bonjour Marion Michel,"
    })
    assert_mail_received_by(MAIL_PHIL, "Envoi avec des exclusions")
    refute_mail_received_by('mail@chez.elle', "Envoi avec des exclusions")
    refute_mail_received_by('quatremail@chez.eux', "Envoi avec des exclusions")

  end

  def test_bonne_definition_des_exclusions
    source = Factory.source_file({name: 'with_exclusions'})
    outs = source.exclusions
    assert_instance_of Hash, outs
    assert outs.count == 2
    assert outs.key?('mail@chez.elle')
    assert outs.key?('quatremail@chez.eux')
  end

end #/class ExclusionsTest
