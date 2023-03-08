require "test_helper"

class MailManagerTest < Minitest::Test
  
  def test_that_it_has_a_version_number
    refute_nil ::MailManager::VERSION
  end

  def test_send_method_responds
    assert_respond_to MailManager, :send
  end

  def test_send_require_path
    assert_raises do 
      MailManager.send
    end
    assert_silent do
      MailManager.send(simple_mail_file)
    end
  end

  def test_path_valid_method
    assert_respond_to MailManager, :path_valid?
    path = simple_mail_file
    assert MailManager.path_valid?(path)
    res = capture_io do
      refute MailManager.path_valid?("#{path}.bad")
    end
    assert_match('mauvaise extension',res.join("\n"))
    res = capture_io do 
      refute MailManager.path_valid?('/bad/fichier/path.md')
    end
    assert_match('introuvable', res.join("\n"))
  end




  def simple_mail_file
    @simple_mail_file ||= File.expand_path('./test/assets/mail_files/simple.md')
  end
end
