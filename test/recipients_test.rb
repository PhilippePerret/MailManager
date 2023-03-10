require 'test_helper'

class RecipientClassTest < Minitest::Test

  def setup
    super
  end


  def test_class_exists
    assert defined?(MailManager::Recipient)
  end

  def test_class_method_load_with_csv_file
    # Test de la méthode MailManager::Recipient::load qui permet
    # de charger une liste de destinatires
    
    assert_respond_to MailManager::Recipient, :load
    assert_raises(ArgumentError) do
      MailManager::Recipient.load
    end

    mailing_csv = listing('ok.csv')

    dsts = MailManager::Recipient.load(mailing_csv)
    assert_instance_of Array, dsts
    first_dst = dsts.first
    assert_instance_of MailManager::Recipient, first_dst
    assert_equal('premier.mail@chez.elle', first_dst.mail)
    assert_equal('Première', first_dst.patronyme)
    assert_equal('F', first_dst.sexe)
    assert(first_dst.femme?)
    refute first_dst.fonction
  end

  def test_class_method_load_with_yaml_file
    # Test de la méthode MailManager::Recipient::load qui permet
    # de charger une liste de destinatires
    
    mailing_yaml = listing('ok.yaml')

    dsts = MailManager::Recipient.load(mailing_yaml)
    assert_instance_of Array, dsts
    first_dst = dsts.first
    assert_instance_of MailManager::Recipient, first_dst
    assert_equal('premier.mail@chez.elle', first_dst.mail)
    assert_equal('Première', first_dst.patronyme)
    assert_equal('F', first_dst.sexe)
    assert(first_dst.femme?)
    refute first_dst.fonction
  end

  # --- Gestion des erreurs ---

  def test_load_with_bad_format
    [
      ['bad_header.csv', 'bad_header'],
      ['bad_extension.txt', 'bad_extension', ['.txt']],
      ['missing_mail.yaml', 'missing_mail'],
      ['missing_sexe.yaml', 'missing_sexe'],
    ].each do |fname, err_id, err_args|
      listing_path = listing(fname)
      err = assert_raises(MailManager::BadListingError) do
        MailManager::Recipient.load(listing_path)
      end
      err_expected = ERRORS['listing'][err_id]
      err_expected = err_expected % err_args if err_args
      assert_match(err_expected[0..50] , err.message[0..50])
    end
  end


  def listing(name)
    File.join(TEST_FOLDER,'assets','emails', name)
  end
end #/class RecipientClassTest
