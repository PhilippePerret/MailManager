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

# @note
#   Seules les propriétés :destinataire et :message ne sont pas
#   remplacées, car elles dépendent du reste.
def code_template_mail
  TEMPLATE % {
    message_id:   message_id,
    sender:       source.sender[:full],
    boundary:     boundary,
    subject:      subject,
    universal_identifier: universal_identifier,
    date_mail: date_mail,
  }
end

# --- Données propres au mail ---

def subject
  @subject ||= source.metadata['subject']  
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
Content-Type: multipart/related;
  type="text/html";
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
To: %%{destinataire}


--%{boundary}
Content-Transfer-Encoding: quoted-printable
Content-Type: text/html;
  charset=utf-8

%%{message}
--%{boundary}--
EML

end #/class Mail
end #/module MailManager
