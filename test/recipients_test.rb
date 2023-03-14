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

  def test_list_of_recipient_files
    # Ce test vérifie qu'on puisse donner une liste de chemin
    # d'accès pour la définition des destinataires
    # 
    str = "[\"/Users/philippeperret/Programmes/Gems/mail_manager/test/assets/emails/ok.csv\",\"/Users/philippeperret/Programmes/Gems/mail_manager/test/assets/emails/ok.yaml\",\"LeMien,H,philippe.perret@yahoo.fr\"]"
    dst = MailManager::Recipient.destinataires_from(str, Factory.source_file(name:'simple'))
    expected = 4 + 4 + 1
    actual   = dst.count
    assert_equal(expected, actual, "La liste des destinataires devrait contenir #{expected} recipients, elle en contient #{actual}…")

  end

  # --- Gestion du nom,prénom,patronyme ---

  def test_decomposition_patronyme
    [
      ['Phil <phil@chez.lui>', 'phil@chez.lui', 'Phil', 'Phil', ''],
      ['Marion MICHEL <marion@chez.elle>', 'marion@chez.elle', 'Marion MICHEL', 'Marion', 'MICHEL'],
      ['Marc-Antoine LARI BOISSIÈRE <malb@chez.eux>','malb@chez.eux','Marc-Antoine LARI BOISSIÈRE', 'Marc-Antoine','LARI BOISSIÈRE'],
      ['Marc Olivier BOISSIÈRE <marco-livier@chez.eux>','marco-livier@chez.eux','Marc Olivier BOISSIÈRE', 'Marc Olivier','BOISSIÈRE'],
      ['Marc Olivier LARGI BOISSIÈRE <marco-livier@chez.eux>','marco-livier@chez.eux','Marc Olivier LARGI BOISSIÈRE', 'Marc Olivier','LARGI BOISSIÈRE'],
    ].each do |donnee, mail, patronyme, prenom, nom|
      re = MailManager::Recipient.new(donnee)
      assert_equal(mail, re.mail, "Le mail devrait être #{mail.inspect}. Il vaut #{re.mail.inspect}…")
      assert_equal(patronyme, re.patronyme, "Le patronyme devrait être #{patronyme.inspect}. Il vaut #{re.patronyme.inspect}…")
      assert_equal(prenom, re.prenom, "Le prenom devrait être #{prenom.inspect}. Il vaut #{re.prenom.inspect}…")
      assert_equal(nom, re.nom, "Le nom devrait être #{nom.inspect}. Il vaut #{re.nom.inspect}…")
    end
  end


  # --- Gestion des erreurs ---

  def test_load_with_bad_format
    # 
    # TODO : IL y a des erreurs ici puisque le code a changé
    [
      ['bad_header.csv'   , 'bad_header'],
      ['bad_extension.txt', 'bad_extension', ['.txt']],
      ['missing_mail.yaml', 'missing_mail'],
      ['missing_sexe.yaml', 'missing_sexe'],
    ].each do |fname, err_id, err_args|
      listing_path = listing(fname)
      err = assert_raises(MailManager::InvalidDataError) do
        MailManager::Recipient.load(listing_path)
      end
      err_expected = ERRORS['listing'][err_id]
      err_expected = err_expected % err_args if err_args
      assert_match(err_expected[0..50] , err.message[0..50])
    end
  end

  def test_check_if_valid
    skip "Implémenter la méthode MailManager::Recipient#check_if_valid"
  end


  def listing(name)
    File.join(TEST_FOLDER,'assets','emails', name)
  end
end #/class RecipientClassTest
