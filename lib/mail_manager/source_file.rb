=begin
  
  class SourceFile
  ----------------
  Gestion du fichier source

=end
require 'kramdown'
module MailManager
class SourceFile

attr_reader :path
attr_reader :metadata
attr_reader :variables

def initialize(path)
  @path = path
  traite_raw_code
  data_valid_or_raise
end

def message
  @message ||= begin
    options = {variables: variables}
    MailManager::Message.new(raw_message, **options).to_html
  end
end
def raw_message ; @raw_message  end
def subject     ; @subject      ||= metadata['subject']  end
def expediteur  ; @expediteur   ||= metadata['from']  end


# @return un destinataire unique ou une liste de destinataires
def destinataire
  @destinataire ||= begin
    dst = metadata['to']
    if dst.match?('@')
      # - Destinataire unique -
    else
      # - Liste de destinataires -
    end
  end
end


# --- Méthodes de traitement du message ---


# Méthode qui check que les métadonnées du fichier source soient bien
# valides (doit contenir les données minimales.
def data_valid_or_raise
  metadata['to']        || raise('missing_to')
  metadata['from']      || raise('missing_from')
  metadata['subject']   || raise('missing_subject')
rescue Exception => e
  raise InvalidDataError, "#{ERRORS['source_file']['invalid_metadata']} : #{ERRORS['source_file'][e.message]}"
end


private

# Traitement du code brut du fichier markdown
# Principalement pour extraire le code du message et le code
# de l'entête.
def traite_raw_code
  @raw_code = File.read(path)
  code = @raw_code.strip.dup
  code.start_with?('---') || raise(ERRORS['source_file']['no_metadata'])
  @raw_message = retire_metadata(code)
end

def retire_metadata(code)
  dec = code.index('---', 10)
  dispatch_metadata(code[3...dec].strip)
  return code[dec+3..-1].strip
end

def dispatch_metadata(code)
  @variables  = {}
  @metadata   = {
    'to'        => nil,
    'from'      => nil,
    'subject'   => nil,
    'ship_date' => nil,
  }
  code.split("\n").each do |line|
    line = line.strip
    next if line.empty? || line.start_with?('#')
    sp = line.split('=')
    key = sp.shift.strip.downcase
    val = sp.join('=').strip
    val = val.sub(/^"/,'').sub(/"$/,'')
    if @metadata.key?(key)
      @metadata.merge!(key => val)
    else
      @variables.merge!(key => val)
    end
  end
  # puts "metadata = #{metadata.inspect}"
end

end #/class SourceFile
end #/module MailManager
