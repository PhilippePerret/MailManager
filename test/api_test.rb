#
# Pour faire jouer ce test :
# 
#     rake test TEST=test/api_test.rb
# 
require 'test_helper'

class GoodRecipient
  def initialize(data)
    @data = data
  end
  def homme?; sexe == 'H' end
  def femme?; sexe == 'F' end
  def patronyme; @data[:patronyme] || mail end
  def mail; @data[:mail] end
  def sexe; @data[:sexe] end
  def variables_template(all_variables)
    {
      mail: mail, sexe: sexe, patronyme: patronyme
    }
  end
end

class RecipientJustMail 
  def mail; end
  def patronyme; end
end
class RecipientMailAndFemme
  def mail; end
  def femme?; end
  def patronyme; end
end

class ApiTest < Minitest::Test

  def setup
    super
  end

  def test_send_doit_recevoir_les_bons_arguments
    #
    # Test que les bons arguments doivent être envoyés, sinon ça
    # génère une erreur
    # 

    # Il doit y avoir des arguments
    err = assert_raises(ArgumentError) do 
      MailManager::API.send
    end
    assert_match('wrong number of arguments', err.message)

    # Le premier argument doit être un message
    # 
    err = assert_raises(ArgumentError) do
      MailManager::API.send(nil, nil, nil)
    end
    assert_match('+message+ devrait être un string', err.message)

    # Le message ne doit pas être vide
    # 
    err = assert_raises(ArgumentError) do
      MailManager::API.send('', nil, nil)
    end
    assert_match('Le message ne devrait pas être vide', err.message)

    # La liste des destinataire doit être une liste
    # 
    err = assert_raises(ArgumentError) do
      MailManager::API.send("Mon Message", nil, nil)
    end
    assert_match('+destinataires+ devrait être une liste', err.message)

    # Il devrait y avoir au moins un destinataire
    # 
    err = assert_raises(ArgumentError) do
      MailManager::API.send('Mon message', [], nil)
    end
    assert_match('Aucun destinataire n’est défini…', err.message)

    # Les destinataires doivent être des instances qui répondent à
    # #mail
    # 
    err = assert_raises(ArgumentError) do
      MailManager::API.send('Mon message', ['mail@chez.moi'], nil)
    end
    assert_match('Les destinataires devraient être des instances qui répondent à la méthode #mail.', err.message)

    # Les destinataires doivent être des instances qui répondent à
    # #femme?
    # 
    # 
    badrecip = RecipientJustMail.new
    err = assert_raises(ArgumentError) do
      MailManager::API.send('Mon message', [badrecip], nil)
    end
    assert_match('Les destinataires devraient être des instances qui répondent à la méthode #femme?.', err.message)

    badrecip = RecipientMailAndFemme.new
    # Les destinataires doivent être des instances qui répondent à
    # #homme?
    # 
    err = assert_raises(ArgumentError) do
      MailManager::API.send('Mon message', [badrecip], nil)
    end
    assert_match('Les destinataires devraient être des instances qui répondent à la méthode #homme?.', err.message)

    dest1 = GoodRecipient.new(mail: 'philippe.perret@yahoo.fr', sexe:'H')
    dest2 = GoodRecipient.new(mail: 'phil@atelier-icare.net', sexe:'F')

    # Les paramètres doivent être définis
    # 
    err = assert_raises(ArgumentError) do
      MailManager::API.send('Mon message', [dest1, dest2], nil)
    end
    assert_match('+params+ devrait être une table (Hash).', err.message)

    # Les paramètres doivent définir :sender
    # 
    err = assert_raises(ArgumentError) do
      MailManager::API.send('Mon message', [dest1, dest2], {})
    end
    assert_match('Les paramètres devraient définir :sender (patronyme<mail>)', err.message)
  
    # Les paramètres doivent définir :sender
    # 
    err = assert_raises(ArgumentError) do
      MailManager::API.send('Mon message', [dest1, dest2], {sender:"badsender"})
    end
    assert_match('params[:sender] (badsender) est mal formaté… (devrait être ’patronyme<mail>’)', err.message)

    # Les paramètres doivent définir :subject
    # 
    err = assert_raises(ArgumentError) do
      MailManager::API.send('Mon message', [dest1, dest2], {sender:"Moi<pour@toi.gmail>"})
    end
    assert_match('+params+ devrait définir le sujet du message (:subject).', err.message)

    # Le sujet devrait être un string
    # 
    err = assert_raises(ArgumentError) do
      MailManager::API.send('Mon message', [dest1, dest2], {subject:12, sender:"Moi<pour@toi.gmail>"})
    end
    assert_match('params[:subject] devrait être une chaine de caractères.', err.message)

    # Le sujet devrait être un string non vide
    # 
    err = assert_raises(ArgumentError) do
      MailManager::API.send('Mon message', [dest1, dest2], {subject:"", sender:"Moi<pour@toi.gmail>"})
    end
    assert_match('Le sujet du message devrait être défini (c’est une chaine vide)…', err.message)

  end

  def test_envoi_le_mail_si_bons_arguments
    #
    # On fait un test avec de bons arguments, ce qui doit envoyer
    # les mails
    # 
    dest1 = GoodRecipient.new(mail: 'philippe.perret@yahoo.fr',sexe:'H', patronyme:'Philippe Perret')
    dest2 = GoodRecipient.new(mail: 'phil@atelier-icare.net', sexe:'F', patronyme:'Phil')

    message = <<~TEXT
    Cher %{patronyme},

    J'espère que vous allez bien.
    
    Bien à vous,
    
    Moi
    TEXT

    params = {
      subject:    "Message du #{Time.now}",
      sender:     'phil<pilou@cendred.fr>',
      simulation: true,
      no_delay:   true,
    }

    # ===> TEST <===
    MailManager::API.send(message, [dest1, dest2], params)

    # ===> VÉRIFICATION <===
    # TODO : Les mails doivent avoir été envoyés
    
  end


end #/ApiTest
