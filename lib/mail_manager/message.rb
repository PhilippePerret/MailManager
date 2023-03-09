=begin

  Class MailManager::Message
  --------------------------
  Traitement du message à envoyer. Depuis son code brut en markdown
  jusqu'à sa version HTML complète, dans une table pour être bien
  dimensionné pour tous les gestionnaires de mail.

=end
module MailManager
class Message

  attr_reader :raw_code
  attr_reader :variables
  attr_reader :options

  def initialize(raw_code, **options)
    @raw_code   = raw_code
    @variables  = options.delete(:variables) || {}
    @options    = options
  end

  # = main =
  # 
  # Méthode de sortie qui retourne le code HTML complet du 
  # message (à partir de raw_code.
  # 
  def to_html
    <<~HTML
    <!DOCTYPE html>
    <html lang="fr">
    #{HEAD}
    <body>
    <table style="#{TABLE_STYLE}">
    #{html_rows}
    </table>
    </body>
    </html>
    HTML
  end


  # @return [HTMLString] les rangées de la table pour le mail
  def html_rows
    traited_code
  end


  def traited_code
    @traited_code ||= begin
      code_html = kramdown(raw_code).strip
      code_html = traite_table_in_kramdown_code(code_html)
      code_html = rowize_kramdown_code(code_html)
      @message  = remplace_variables_in(code_html)
    end
  end

  # Méthode qui définit la constante TR_IN pour création des 
  # cellules. Principalement, elle permet de régler certaines
  # valeurs qui peuvent être redéfinies comme la police et la taille
  def tr_in
    @tr_in ||= begin
      data_style = {
        font_family: options[:font_family] || 'Times',
        font_size:   options[:font_size] || '14pt'
      }
      "<tr><td style=\"#{TD_STYLE % data_style}\">".freeze
    end
  end

# --- Méthodes de traitement du code brut ---

def kramdown(code_md)
  Kramdown::Document.new(code_md).to_html
end

# Méthode qui reçoit le code HTML produit par kramdown et
# traite les tables.
# Pour qu'elles puissent être traitées par la méthode suivante,
# il faut les mettre dans des "<p>…</p>" et il faut aussi traiter
# les codes intérieurs qui peuvent définir des alignements
def traite_table_in_kramdown_code(code_html)
  return code_html if not(code_html.match?('<table>'))
  code_html = code_html
    .gsub(/<table>/, '<p><table width="100%">')
    .gsub(/<\/table>/, '</table></p>')
  # 
  # Boucle sur le contenu de toutes les cellules
  # 
  code_html = code_html.gsub(/<td>(.+?)<\/td>/) do
    content = $1.freeze
    if content.match?('::')
      align, real_content = content.split('::')
      "<td style=\"text-align:#{align};\">#{real_content}</td>"
    else
      "<td>#{content}</td>"
    end
  end
end

# Méthode qui reçoit le code HTML produit par kramdown et
# remplace les paragraphes par des rangées de table
def rowize_kramdown_code(code_kd)
  code_kd
    .gsub(REG_START_PARAGRAPH , tr_in)
    .gsub(REG_END_PARAGRAPH   , TR_OUT)
end

# Remplace toutes les variables dans le code HTML 
# 
# @note
#   Ces variables sont définies dans les métadata, ce
#   sont les données autres que les données utiles.
# 
def remplace_variables_in(code_html)
  variables.each do |key, val|
    if key.start_with?('IMG') && not(key.end_with?('-alt'))
      val = traite_variable_as_image(key, val)
    end
    code_html = code_html.gsub(/#{key}/, val)
  end
  return code_html
end

def traite_variable_as_image(key, img_path)
  legende = if variables.key?("#{key}-alt")
    metadata["#{key}-alt"]
  else
    File.basename(img_path)
  end
  ImageManager.code_image(img_path, legende)
end

# --- CONSTANTES ---

REG_START_PARAGRAPH = /^<p>/.freeze
REG_END_PARAGRAPH   = /<\/p>$/.freeze

TABLE_STYLE = "max-width:840px;"

TD_STYLE = <<-CSS.split("\n").join(';')
text-align:justify
caret-color:rgb(0,0,0)
color:rgb(0,0,0)
font-family:%{font_family},serif
font-size:%{font_size}
font-style:normal
font-variant-caps:normal
font-weight:400
letter-spacing:normal
text-indent:0px
text-transform:none
white-space:normal
orphans:auto
widows:auto
word-spacing:0px
-webkit-text-size-adjust:auto
-webkit-text-stroke-width:0px
text-decoration:none
float:none
CSS

# TR_IN est défini dynamiquement plus haut
TR_OUT  = "</td></tr>".freeze

HEAD = <<~HTML
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Contenu du mail</title>
  <style type="text/css">
    body {max-width:840px;}
    table tr td {padding: 0.5em 0;}
  </style>
</head>

HTML

end #/class Message
end #/module MailManager