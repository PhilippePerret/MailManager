require 'test_helper'
class MessageMailTest < Minitest::Test

  def setup
    super
  end

  def msg(str)
    MailManager::Message.new(str)
  end

  def test_message_class
    assert defined?(MailManager::Message), "La classe MailManager::Message devrait être définie."
  end

  def test_to_html_method
    assert_respond_to(msg(''), :to_html)
    # Un test le plus simple possible
    imsg = msg('Bonjour tout le monde !')
    expected = expected_with_rows(["Bonjour tout le monde !"])
    actual = imsg.to_html

    assert_equal(expected, actual, "La méthode MailManager::Message.to_html ne produit pas le bon code…")
  end

  def test_to_html_with_two_paragraphs
    str = "Un premier paragraphe.\n\nUn deuxième paragraphe."
    imsg = MailManager::Message.new(str)
    expected = expected_with_rows(str.split("\n\n"))
    actual   = imsg.to_html
    assert_equal(expected, actual, "La méthode MailManager::Message.to_html ne produit pas le bon code…")
  end

  def test_to_html_with_variables
    str = "Un texte avec une VARIABLE à corriger."
    options = {variables: {'VARIABLE' => 'constante'}}
    imsg = MailManager::Message.new(str, **options)
    expected = expected_with_rows(["Un texte avec une constante à corriger."])
    actual   = imsg.to_html
    assert_equal(expected, actual, "La méthode MailManager::Message.to_html ne produit pas le bon code…")
  end

  def test_to_html_with_table
    str = "Bonjour,\n\n| Un item | center::item 2 | right::item 3 |"
    imsg = MailManager::Message.new(str)
    tbl = <<-HTML.strip
<table width=\"100%\">
  <tbody>
    <tr>
      <td>Un item</td>
      <td style=\"text-align:center;\">item 2</td>
      <td style=\"text-align:right;\">item 3</td>
    </tr>
  </tbody>
</table>
    HTML
    expected = expected_with_rows(['Bonjour,', tbl])
    actual   = imsg.to_html
    # debug (pour voir le fichier)
    # File.open("./test/essai.html",'wb'){|f|f.write actual}
    # /debug
    assert_equal(expected, actual, "La méthode MailManager::Message.to_html ne produit pas le bon code…")

  end

  def test_to_html_with_image
    str   = "Une image IMG1 pour voir."
    img_path = File.join(TEST_FOLDER,'assets','images','petite.jpg')
    opts  = {variables: {'IMG1' => img_path }}
    imsg = MailManager::Message.new(str, **opts)
    code64 = Factory::Image.base64(img_path)
    expected = expected_with_rows(["Une image <img src=\"data:image/jpg;base64,#{code64}\" alt=\"petite.jpg\"> pour voir."])
    actual   = imsg.to_html
    assert_equal(expected, actual, "La méthode MailManager::Message.to_html ne produit pas le bon code…")
  end


  # @return [HTMLString] le texte complet du message
  def expected_with_rows(rows, imsg = nil)
    @default_row ||= begin
      imsg ||= MailManager::Message.new('')
      "#{imsg.tr_in}%s</td></tr>\n".freeze
    end
    rows = rows.map do |row|
      @default_row % row
    end.join("\n").strip
    <<~HTML
    <!DOCTYPE html>
    <html lang="fr">
    #{head}
    <body>
    <table style="#{table_style}">
    #{rows}
    </table>
    </body>
    </html>
    HTML
  end

  def td_style
    @td_style ||= MailManager::Message::TD_STYLE 
  end
  def table_style
    @table_style ||= MailManager::Message::TABLE_STYLE
  end
  def head
    @head ||= MailManager::Message::HEAD
  end
end #/MessageMailTest
