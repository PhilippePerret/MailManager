module MailManager
class SourceFileMailType < SourceFile


def destinataires
  @destinataires ||= begin
    table_exclus = exclusions
    dsts = init_destinataires = super.reject do |recipient|
      table_exclus.key?(recipient.mail)
    end.map do |recipient|
      {name: "#{recipient.patronyme} <#{recipient.mail}>", value: recipient}
    end
    clear
    [Q.select("Envoyer à : ".jaune, dsts, **{per_page:console_height - 3,filter:true})]
  end
end

end #/class SourceFileMailType
end #/module MailManager
