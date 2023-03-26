require 'minitest/assertions'

module Minitest::Assertions

  # @param [String] email_address L'adresse email
  # @param [String|Regexp|Hash] params  Le sujet du mail  ou une table (cf. manuel)
  def assert_mail_received_by(email_address, params = nil)
    params ||= {}
    params = {subject: params} if params.is_a?(String) || params.is_a?(Regexp)
    params.merge!(to: email_address)
    assert(Factory::Mail.has?(params), Proc.new{traite_last_message_error})
  end

  # Inverse de la précédente
  def refute_mail_received_by(email_address, params = nil)
    params ||= {}
    params = {subject: params} if params.is_a?(String) || params.is_a?(Regexp)
    params.merge!(to: email_address)
    refute(Factory::Mail.has?(params), Proc.new{traite_last_message_error})
  end

  def traite_last_message_error
    msg = [""]
    Factory::Mail.last_errors.each do |err|
      case err
      when Factory::Mail
        msg << err.formate_errors
      when String
        msg << err
      else
        raise "Je ne sais pas traiter un message d'erreur de class #{err.class}…"
      end
    end
    return "\n  -" + msg.join("\n  -")
  end
end #/module Minitest::Assertions
