=begin
# class MailManager::API
# ----------------------
# L'idée de cette classe est de permettre d'appeler MailManager
# de l'extérieur pour envoyer un mailing sans avoir le fichier
# requis.
#
=end
module MailManager
class API

  ##############################################
  # @public
  # @main
  # @entry
  # 
  # Méthode d'entrée pour envoyer un mailing
  #   MailManager::API.send(
  #     <path au message>,
  #     <destinataires>[,
  #     <options>]
  #   )
  ##############################################
  # 
  # @param [String] path_message Le chemin d'accès au message
  # @param [Array<Instance>] destinataires Liste d'instance de destinataires (voir dans le manuel les méthodes auxquels ils doivent répondre)
  # @param [Hash] params Table des options/paramètres à appliquer
  # 
  # @return [Hash] Le résultat obtenu avec, notamment, les destinataires qui ont pu être contactés et les erreurs éventuels
  # {
  #   recipients_ok: [Array<Recipient> recipients à qui le mail a pu être envoyé>], 
  #   recipients_ko: [Array<{recipient: [Recipient], raison:[String]}>]
  # }
  def self.send(path_message, destinataires, params)
    #
    # On vérifie si tout est bon
    # 
    path_message.is_a?(String) || raise(ArgumentError.new("+path_message+ devrait être un string, le message brut à envoyer."))
    File.exist?(path_message) || raise(ArgumentError.new('Le fichier du message est introuvable.'))
    
    destinataires.is_a?(Array) || raise(ArgumentError.new('+destinataires+ devrait être une liste (de destinataires).'))
    destinataires.count > 0 || raise(ArgumentError.new('Aucun destinataire n’est défini…'))
    firstrec = destinataires.first
    firstrec.respond_to?(:mail) || raise(ArgumentError.new('Les destinataires devraient être des instances qui répondent à la méthode #mail.'))
    firstrec.respond_to?(:patronyme) || raise(ArgumentError.new('Les destinataires devraient être des instances qui répondent à la méthode #patronyme.'))
    firstrec.respond_to?(:femme?) || raise(ArgumentError.new('Les destinataires devraient être des instances qui répondent à la méthode #femme?.'))
    firstrec.respond_to?(:homme?) || raise(ArgumentError.new('Les destinataires devraient être des instances qui répondent à la méthode #homme?.'))
    firstrec.respond_to?(:variables_template) || raise(ArgumentError.new('Les destinataires devraient être des instances qui répondent à la méthode #variables_template.'))

    params.is_a?(Hash) || raise(ArgumentError.new("+params+ devrait être une table (Hash)."))
    params.key?(:sender) || raise(ArgumentError.new("Les paramètres devraient définir :sender (patronyme<mail>)"))    
    params[:sender].match?('@') || raise(ArgumentError.new("params[:sender] (#{params[:sender]}) est mal formaté… (devrait être ’patronyme<mail>’)"))

    #
    # Méthodes à implémenter si elles n'existent pas
    # 
    # #as_to
    unless firstrec.respond_to?(:as_to)
      firstrec.class.define_method(:as_to) do
        "#{patronyme}<#{mail}>"
      end
    end

    #
    # Définir la liste des destinataires
    # 
    MailManager::Recipient.final_recipients = destinataires

    # 
    # Indiquer qu'il n'y a aucun exclusion
    # 
    MailManager::Recipient.exclusions = []

    #
    # Mocker source_file (MailManager::SourceFile)
    # 
    # source_file = FakeSourceFile.new(message, params)
    # source_file = SourceFile.new(path_message)
    source_file = FakeSourceFile.new(path_message)
    # - définir @sender (Hash avec :full) -
    source_file.sender = {full: params[:sender], mail: nil, patronyme:nil}

    #
    # Mocker le message
    # 
    # imessage = MailManager::Message.new(source_file, message, {mail_type: true})

    # - pour définir SourceFile@message -
    # - pour définir SourceFile@message_plain_text -
    # source_file.instance_mail_message = imessage

    #
    # Mocker mail (MailManager::Mail)
    # 
    mail = MailManager::Mail.new(source_file)
    # mail.subject = params[:subject] || raise("Il faut définir le sujet (params[:subject])")

    #
    # Instance de l'expéditeur
    # 
    sender = Sender.new(mail, source_file)

    puts "params[:simulation] est #{params[:simulation].inspect}"
    sleep 3
    sender.activate_simulation(params[:simulation])

    if params[:no_delay]
      def sender.no_delai? 
        true 
      end
    end

    #
    # On procède à l'envoi
    # 
    resultat = sender.send

    #
    # On retourne le résultat
    # 
    return resultat
  end

end #/class API

#
# class MailManager::FakeSourceFile
# (NE SERT PLUS, NORMALEMENT)
class FakeSourceFile < SourceFile
  # @api @private
  # @param [Hash] value {:full, :mail, :patronyme}
  def sender=(value) 
    @sender = value
  end
end #/class FakeSourceFile
end #/module MailManager
