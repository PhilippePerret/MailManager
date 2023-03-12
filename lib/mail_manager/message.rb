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
    # puts "options : #{options.inspect}".jaune
    @variables  = options.delete(:variables) || {}
    @options    = options
  end

  # = main =
  # 
  # Méthode de sortie qui retourne le code HTML complet du 
  # message (à partir de raw_code).
  # 
  # - On assemble le code est on 
  # - on le transforme en quoted-printable
  # - on le découpage en ligne de 76 caractères
  def to_html
    assemblage
  end

  # Construction du code complet
  # 
  # @return [HTMLString] Le code complet du message en HTML
  # 
  # def assemblage
  #   <<~HTML
  #   <!DOCTYPE html>
  #   <html lang="fr">
  #   <head>
  #   #{HEAD}
  #   <style type="text/css">
  #   #{head_style}
  #   </style>
  #   </head>
  #   <body>
  #   #{tested_code}
  #   </body>
  #   </html>
  #   HTML
  # end
  def assemblage
    <<~HTML
    <!DOCTYPE html>
    <html lang="fr">
    <head>
    #{HEAD}
    <style type="text/css">
    #{head_style}
    </style>
    </head>
    <body>
    <table id="main">
    #{html_rows}
    </table>
    </body>
    </html>
    HTML
  end


  # Pour tester du code brut (rien ajouté au body à part ça)
  def tested_code
    # 
    # DEV - POUR FAIRE DES ESSAIS
    # 
    # Marche, avec <table width="400">
    return <<~HTML
    <table id="main">
      <tr><td>#{LOREM_1}</td></tr>
    </table>
    HTML
  end

  def head_style
    <<~CSS
    <!--
    table#main {
      width:800px;
    }
    table#main tr td {
      padding: 0.5em 0;
      text-align:justify;
    }
    -->
    CSS
  end

  # def head_style
  #   "table tr td {padding: 0.5em 0;}"
  # end


  # @return [HTMLString] les rangées de la table pour le mail
  def html_rows
    traited_code
  end


  def traited_code
    @traited_code ||= begin
      code      = escape_variables_recipients(raw_code)
      code_html = kramdown(code).strip
      @plain_text = code_html.dup
      code_html = traite_table_in_kramdown_code(code_html)
      code_html = rowize_kramdown_code(code_html)
      code_html = remplace_images_in(code_html)
      @message  = remplace_variables_in(code_html)
    end
  end


  def to_plain 
    @plain_text = remplace_variables_in(raw_code.dup)
    @plain_text = remplace_images_with_alt(@plain_text)
    return @plain_text
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

# Traite toutes les variables %{…} dans le code pour qu'elles
# ne soit pas interprétées tout de suite
def escape_variables_recipients(codebrut)
  codebrut
end

def kramdown(code_md)
  Kramdown::Document.new(code_md).to_html
end

# Méthode qui reçoit le code HTML produit par kramdown et
# traite les tables.
# Pour qu'elles puissent être traitées par la méthode suivante,
# il faut les mettre dans des "<p>…</p>" et il faut aussi traiter
# les codes intérieurs qui peuvent définir des alignements
# 
# @param [HTMLString] code_html Code produit par kramdown
# 
def traite_table_in_kramdown_code(code_html)
  return code_html if not(code_html.match?('<table>'))
  code_html = code_html
    .gsub(/<table>/, '<p><table width="100%%">')
    .gsub(/<\/table>/, '</table></p>')

  # On procède table par table pour compter le nombre de cellules
  # et ajouter, pour windows, la taille de chacune. Sinon, la première
  # et la dernière se règlent en fonction du contenu et les autres
  # prennent toutes la place.
  # 
  code_html = code_html.gsub(/<table(.+?)<\/table>/m) do
    '<table' + traite_colonnes_in_table($1.freeze) + '</table>'
  end
end

def traite_colonnes_in_table(code_table)
  # 
  # Nombre de colonnes
  # 
  decin = code_table.index('<tr')
  decou = code_table.index('</tr>', decin)
  range = code_table[decin..decou]
  nombre_colonnes = range.split('</td>').count - 1

  # 
  # Boucle sur le contenu de toutes les cellules de la table
  # 
  code_table = code_table.gsub(/<td>(.+?)<\/td>/) do
    content = $1.freeze
    if content.match?('::')
      align, real_content = content.split('::')
      "<td width=\"__TD_WIDTH__\" style=\"text-align:#{align};\">#{real_content}</td>"
    else
      "<td width=\"__TD_WIDTH__\">#{content}</td>"
    end
  end
  # 
  # Taille de chaque colonne
  # 
  td_width = "#{100 / nombre_colonnes}%%"
  # 
  # On met la taille de chaque colonne
  # 
  code_table = code_table.gsub(/__TD_WIDTH__/, td_width)
  # 
  # Pour remplacer le code
  # 
  return code_table
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
    code_html = code_html.gsub(/#{key}/, val)
  end
  return code_html
end

# Remplace toutes les images définies par une variables dans le
# code HTML
def remplace_images_in(code_html)
  ImageManager.each do |image|
    code_html = code_html.gsub(/#{image.key}/, image.to_html)
  end
  return code_html
end
def remplace_images_with_alt(plain_code)
  ImageManager.each do |image|
    plain_code = plain_code.gsub(/#{image.key}/, "[image #{image.alt}]")
  end
  return plain_code
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


#    body {max-width:840px;}
HEAD = <<~HTML
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Contenu du mail</title>
HTML

LOREM_1 = <<-TEXT.strip
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam nec elit vel sapien interdum aliquet. Donec tincidunt risus lectus, et ultrices augue ornare vitae. Phasellus tempus augue ac finibus convallis. Donec sit amet urna quis mauris suscipit auctor. Morbi sed orci ut tortor rutrum cursus. Integer sagittis pharetra felis sagittis sagittis. Praesent ac risus ut metus malesuada lacinia vel eu enim. Aenean pharetra dignissim bibendum. Phasellus ac lectus gravida, sagittis justo non, congue purus. Nullam vitae justo neque. Sed blandit id arcu et faucibus. Aliquam lacinia metus at faucibus dictum. In id feugiat odio. Sed finibus eu urna id venenatis. Morbi non dolor arcu. Sed ornare mi urna, ut vulputate tellus tristique ac.
TEXT
LOREM_2 = <<-TEXT.strip
Aliquam et blandit elit. Mauris porta vulputate leo, sed maximus ante ultrices sed. Duis facilisis varius auctor. Sed vitae dapibus lacus, eget porta massa. Integer in lacus sit amet purus vehicula luctus quis non lacus. Fusce euismod ipsum at sollicitudin rutrum. Aliquam posuere quis diam sit amet malesuada. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Integer faucibus, odio a mattis cursus, metus sapien tincidunt quam, at scelerisque nibh nibh vel libero. In dapibus sem id orci sagittis gravida quis quis risus. Fusce vitae tortor in lectus congue facilisis ac id velit.
TEXT
LOREM_3 = <<-TEXT.strip
Curabitur mollis augue commodo, elementum libero vitae, tincidunt risus. Morbi aliquet rhoncus ligula, id aliquam dui commodo sit amet. Nunc id justo hendrerit, venenatis sem ac, tempor arcu. Praesent tristique velit turpis, sit amet molestie lectus elementum sit amet. Suspendisse ac dolor eros. Ut vel leo feugiat, rhoncus nisi a, semper magna. Sed tristique condimentum erat ut maximus. Ut ornare lectus vitae suscipit elementum. In pulvinar quis neque a mollis. Vestibulum vel nunc finibus, sodales ante in, fermentum elit. Proin faucibus quis est ac varius. Morbi laoreet felis sed nibh luctus scelerisque. Curabitur dignissim, ipsum id mollis dapibus, enim nunc auctor risus, mattis varius elit tellus sed mauris. Maecenas tincidunt eleifend purus, eget auctor libero.
TEXT
LOREM_4 = <<-TEXT.strip
Nullam eu ante nisi. Donec maximus lacus a neque congue aliquam. Proin sodales ex a odio placerat imperdiet. Integer commodo ligula nec tellus iaculis, ut auctor sem dictum. Vestibulum auctor, dolor vel viverra feugiat, massa augue convallis orci, sed ultrices nulla velit interdum sapien. Nulla aliquet eget quam eu maximus. Morbi non convallis diam, non imperdiet lorem.
TEXT
LOREM_5 = <<-TEXT.strip
Aliquam enim nulla, condimentum id semper in, convallis vitae mi. Mauris aliquet viverra condimentum. Cras congue tellus sit amet mi gravida iaculis. Nullam iaculis ipsum sollicitudin est vulputate accumsan. Nunc in pellentesque odio. Nunc posuere hendrerit felis id condimentum. Ut sed luctus erat, a lacinia dui. Vivamus accumsan facilisis nulla eget condimentum. Donec libero nulla, dapibus quis eleifend eget, molestie vel neque. Vestibulum a urna eu eros tempor commodo. Vivamus urna ipsum, tincidunt in risus sed, vulputate sagittis velit. Donec quis vestibulum lorem, at euismod felis. Aenean tristique massa ac malesuada consequat. Aenean sagittis tempor nulla at eleifend. Integer sit amet ultricies augue, ut varius nulla. Vivamus cursus quam in turpis placerat, sed volutpat ex molestie.
TEXT
LOREM_5_PARAGRAPHES = <<-TEXT.strip
#{LOREM_1}

#{LOREM_2}

#{LOREM_3}

#{LOREM_4}

#{LOREM_5}
TEXT
end #/class Message
end #/module MailManager
