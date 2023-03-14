=begin
  Module permettant de tester les exclusions
=end
require 'test_helper'
class ExclusionsTest < Minitest::Test

  def setup
    super
  end

  def teardown
    super
  end

  def test_ne_traite_pas_les_exclus
    # (test live)
    # Ce test permet de vérifier que les exclus ne reçoivent pas
    # les mails
    # 

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
