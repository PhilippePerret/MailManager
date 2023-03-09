require 'test_helper'

class SenderMailTest < Minitest::Test
  
  def setup
    super
  end

  def sender
    @sender ||= begin
      MailManager::Sender.new(mail, source_file)
    end
  end

  def source_file
    @source_file ||= Factory.source_file('pour_moi')
  end

  def mail
    @mail ||= MailManager::Mail.new(source_file)
  end


  def test_method_send_respond
    assert_respond_to sender, :send
  end

  def test_method_send
    
  end

  def test_code_mail_final
    assert_respond_to sender, :code_mail_final
    # code = sender.code_mail_final(source_file.destinataires.first)
    # puts "code:\n#{code}".bleu
    sender.send
    # essai = File.open('./test/essai.eml','wb')
    # essai.puts code
  end


end #/class SenderMailTest
