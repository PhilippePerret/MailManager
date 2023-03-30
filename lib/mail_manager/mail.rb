=begin
  
  class Mail
  ----------------
  Gestion de la fabrication du mail en tant que fichier
  Alors que…
    MailManager::SourceFile a traité le fichier envoyé
    MailManager::Message a traité le message du mail du fichier
  … cette classe va fabriquer un message qui pourra être envoyé par
  la classe MailManager::Sender

=end
require 'securerandom'
module MailManager
class Mail

attr_reader :source

# @param [MailManager::SourceFile] L'instance du fichier source
def initialize(source)
  @source = source
end

# - raccourci -
def name; source.name end

# @param [MailManager::Message] message Instance du message du fichier source
# @param [MailManager::Recipient] recipient Destinataire du message
def assemble_code_final(recipient)
  # 
  # Message initial
  # 
  body = source.message.dup
  body_brut = source.message_plain_text.dup

  #
  # Liste des variables (%{…})
  # 
  @variables_templates ||= begin
    @replace_variable = false
    body.scan(/\%\{(.+?)\}/).map do |found|
      found[0]
    end.uniq.map do |var|
      @replace_variable = true # dès qu'il y en a une
      var.to_sym
    end
  end

  # 
  # Finaliser le message pour le destinataire
  # 
  if @replace_variable
    data_template = recipient.variables_template(@variables_templates)
    begin
      body      = body % data_template
      body_brut = body_brut % data_template
    rescue Exception => e
      puts "Problème avec un mail : #{e.message}".rouge
      puts "body = #{body[0..200].inspect}".rouge
      puts "data_template = #{data_template.inspect}".rouge
      puts e.backtrace.join("\n").orange
      exit 100
    end
  end

  # 
  # Encoder et découper le message
  # 
  body      = [body].pack("M").strip
  body_brut = [body_brut].pack("M").strip


  # 
  # Assemblage du code final
  # 
  cmail = TEMPLATE % {
    message_id:     message_id,
    sender:         source.sender[:full],
    boundary:       boundary,
    subject:        subject,
    universal_identifier: universal_identifier,
    date_mail:      date_mail,
    message:        body,
    message_brut:   body_brut,
    destinataire:   recipient.as_to
  }

  return cmail
end

# --- Données propres au mail ---

def subject
  @subject ||= source.subject
end

def boundary
  @boundary ||= begin
    "Mail-Builder=#{SecureRandom.uuid.upcase}"
  end
end

def universal_identifier
  @universal_identifier ||= SecureRandom.uuid.upcase
end

def message_id
  @message_id ||= SecureRandom.uuid.upcase + "@icare-editions.fr"
end

def date_mail
  @date_mail ||= Time.now.strftime('%a, %e %b %Y %H:%M:%S %z')
end


TEMPLATE = <<~EML
Content-Type: multipart/alternative;
  boundary="%{boundary}"
Subject: %{subject}
Mime-Version: 1.0 (Mac OS X Mail 16.0 \(3696.120.41.1.1\))
X-Apple-Base-Url: x-msg://7/
X-Universally-Unique-Identifier: %{universal_identifier}
X-Apple-Mail-Remote-Attachments: YES
From: %{sender}
X-Apple-Windows-Friendly: 1
Date: %{date_mail}
Message-Id: <%{message_id}>
X-Uniform-Type-Identifier: com.phil.mail-draft
To: %{destinataire}

--%{boundary}
Content-Type: text/plain;
  charset="iso-8859-1"
Content-Transfer-Encoding: quoted-printable

%{message_brut}

=20

=20

--%{boundary}
Content-Transfer-Encoding: quoted-printable
Content-Type: text/html;
  charset=utf-8

%{message}
--%{boundary}--
EML

end #/class Mail
end #/module MailManager
