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

def instance_mail_message
  @instance_mail_message ||= begin
    options = {variables: variables}
    MailManager::Message.new(raw_message, **options)
  end
end

def message
  @message ||= begin
    instance_mail_message.to_html
  end
end
def message_plain_text
  instance_mail_message.to_plain
end

def raw_message ; @raw_message  end
def subject     ; @subject      ||= metadata['subject']  end
def sender
  @sender ||= begin
    fr = metadata['from']
    if fr.match?(/</)
      found = fr.match(/^(.+?)<(.+?)>$/)
      {full: fr, mail: found[2].strip, patronyme: found[1].strip}
    else
      {full: fr, mail: fr, patronyme: nil}
    end
  end
end

# --- Recipients & Exclusions Methods ---

# @return [Array<MailManager::Recipient>] la liste de destinataires
# même s'il n'y en a qu'un seul.
def destinataires
  @destinataires ||= MailManager::Recipient.destinataires_from(metadata['to'], self, **metadata)
end

def exclusions
  @exclusions ||= begin
    tbl = {}
    if metadata['excludes']
      options = {only_mail: true}.merge(metadata)
      MailManager::Recipient.destinataires_from(metadata['excludes'], self, **options).each do |recipient|
        tbl.merge!(recipient.mail => recipient)
      end
    end
    tbl
  end
end

# --- Predicate Methods ---

# @return true si le patronyme est requis dans le message
def require_patronyme?
  raw_message.match?(/\%\{patronyme\}/i)
end

# @return true si le sexe est requis dans le message
def require_sexe?
  defined?(REG_FEMININES) || begin
    Recipient.const_set('REG_FEMININES', /\%\{(#{FEMININES['F'].keys.join('|')})\}/)
  end
  raw_message.match?(REG_FEMININES)
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
    'excludes'  => nil,
  }
  code.split("\n").each do |line|
    line = line.strip
    next if line.empty? || line.start_with?('#')
    sp = line.split('=')
    key_ini = sp.shift.strip
    key = 
    key = key_to_real_key(key_ini) # rectif (p.e. exclude=>excludes)
    val = sp.join('=').strip
    val = val.sub(/^"/,'').sub(/"$/,'')
    if @metadata.key?(key)
      # - Une métadonnée connue -
      @metadata.merge!(key => val)
    elsif key_ini.start_with?('IMG')
      # - Une image - 
      ImageManager.traite_metadata(key_ini, val)
    else
      # - une variable quelconque -
      @variables.merge!(key_ini => val)
    end
  end
end

def key_to_real_key(k_ini)
  k = k_ini.dup.downcase
  return KEY_TO_REAL_KEY[k] || k
end

KEY_TO_REAL_KEY = {
  'exclude' => 'excludes'
}
end #/class SourceFile
end #/module MailManager
