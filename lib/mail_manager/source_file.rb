=begin
  
  class SourceFile
  ----------------
  Gestion du fichier source

=end
require 'kramdown'
module MailManager
class SourceFile

attr_reader :path
def initialize(path)
  @path = path
  traite_raw_code
end


def metadata    ; @metadata     end
def raw_message ; @raw_message  end
def subject     ; @subject ||= metadata['subject']  end
def expediteur  ; @expediteur ||= metadata['from']  end


# @return un destinataire unique ou une liste de destinataires
def destinaire
  @destinaire ||= begin
    dst = metadata['to']
    if dst.match?('@')
      # - Destinataire unique -
    else
      # - Liste de destinataires -
    end
  end
end

# Traitement du message brut en markdown
def traite_message
  code_html = kramdown(raw_message)
  @message  = remplace_variables_in(code_html)
end



# TODO
#   Un problème subsiste ici : comment mettre tout le
#   texte dans une table (seule manière de ne pas avoir
#   sur windaube des messages interminables à droite)
# 
def kramdown(code_md)
  Kramdown::Document.new(code_md).to_html
end

# --- Méthodes de traitement du message ---

# Remplace toutes les variables dans le code HTML 
# 
# @note
#   Ces variables sont définies dans les métadata, ce
#   sont les données autres que les données utiles.
# 
def remplace_variables_in(code_html)
  metadata.each do |key, val|
    if key.start_with?('IMG') && not(key.end_with?('-alt'))
      val = traite_variable_as_image(key, val)
    end
    code_html = code_html.gsub(/#{key}/, val)
  end
  return code_html
end

def traite_variable_as_image(key, img_path)
  legende = if metadata.key?("#{key}-alt")
    metadata["#{key}-alt"]
  else
    File.basename(img_path)
  end
  img = ImageManager.code_image(img_path, legende)

end


private

# Traitement du code brut du fichier markdown
# Principalement pour extraire le code du message et le code
# de l'entête.
def traite_raw_code
  @raw_code = File.read(path)
  code = @raw_code.strip.dup
  code_start_with?('---') || raise(ERRORS['source_file']['no_metadata'])
  @raw_message = retire_metadata(code)
end

def retire_metadata(code)
  dec = code.index('---', 10)
  traite_metadata(code[3...dec].strip)
  return code[dec+3..-1].strip
end

def traite_metadata(code)
  @metadata = {}
  code.split("\n").each do |line|
    line = line.strip
    next if line.empty? || line.start_with?('#')
    sp = line.split('=')
    key = sp.shift.strip
    val = sp.join('=').strip
    val = val.sub(/^"/,'').sub(/"$/,'')
    @metadata.merge!(key.downcase => val)
  end
  # puts "metadata = #{metadata.inspect}"
end

end #/class SourceFile
end #/module MailManager
