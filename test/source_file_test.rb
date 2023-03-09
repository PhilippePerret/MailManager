require 'test_helper'

class SourceFileTest < Minitest::Test

  def setup
    super
  end

  def sourcefile
    @sourcefile ||= Factory.source_file
  end

  def test_respond_to_data_valid_or_raise
    assert_respond_to sourcefile, :data_valid_or_raise
  end

  # Test du test de la validité des métadonnées du fichier source,
  # pour s'assurer qu'il contient bien les données minimales.
  def test_data_valid_or_raise
    default_metadata = {
      'To'      => 'phil@chez.lui',
      'From'    => 'phil@chez.com',
      'Subject' => "Sujet du mail",
    }

    [
      ['To', 'missing_to'],
      ['From', 'missing_from'],
      ['Subject', 'missing_subject'],
    ].each do |key, key_error|

      srcpath = build_source_file_with_metadata('test', default_metadata.merge(key => nil))
      res = assert_raises(MailManager::InvalidDataError) do
        MailManager::SourceFile.new(srcpath)
      end
      assert_equal("#{ERRORS['source_file']['invalid_metadata']} : #{ERRORS['source_file'][key_error]}", res.message)

    end
  end



  # Construction d'un fichier source à partir des données métadata +md+
  def build_source_file_with_metadata(fname, md)
    srcpath = Factory.build_source_file({name: fname, message: "Bonjour à vous", metadata: md})
    return srcpath
  end
end #/class SourceFileTest
