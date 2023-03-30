=begin
  
  class SourceFile
  ----------------
  Gestion du fichier source

=end
require 'kramdown'
module MailManager
class SourceFile

# Liste des données métadata qu'on peut trouver
# 
# @note
#   Toute autre donnée sera ignorée
# 
METADATA_NAMES = ['name','to','from','type','subject','ship_date','excludes']

attr_reader :path
attr_reader :metadata
attr_reader :variables

def initialize(path)
  @path = path
  require_module if module?
  traite_raw_code
  data_valid_or_raise
end

# Méthode qui requierd le module qui accompagne peut-être le mail
def require_module
  require module_path
  Message     .include MessageExtension     if defined?(MessageExtension)
  Message.extend MessageClassExtension      if defined?(MessageClassExtension)
  self.class  .include SourceFileExtension  if defined?(SourceFileExtension)
  self.class  .extend SourceFileClassExtension  if defined?(SourceFileClassExtension)
  Sender      .include SenderExtension      if defined?(SenderExtension)
  Sender      .extend SenderClassExtension  if defined?(SenderClassExtension)
  Recipient.include RecipientExtension      if defined?(RecipientExtension)
  Recipient.extend(RecipientClassExtension) if defined?(RecipientClassExtension)
end

# --- Message methods ---

def instance_mail_message
  @instance_mail_message ||= begin
    options = {variables: variables, mail_type: mail_type?}
    MailManager::Message.new(self,raw_message, **options)
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

# --- Méthodes de données ---

# Pour parler du message, un nom qui doit le décrire assez bien.
# En cas d'absence de cette donnée, c'est l'affixe qui est pris,
# où les _ et les - sont remplacés par des espaces
def name
  @name ||= begin
    metadata['name'] || begin
      File.basename(path,File.extname(path)).gsub(/[_\-]/,' ')
    end
  end
end
def raw_message ; @raw_message  end
def subject     ; @subject      ||= metadata['subject']   end
def subject=(v) ; @subject        = v end
def type        ; @type         ||= metadata['type']      end
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
# 
# @note
#   La méthode est surclassée quand il s'agit d'un mail-type. Cf. 
#   dans le fichier source_file_mail_type
# 
def destinataires
  @destinataires ||= MailManager::Recipient.recipients(self)
end


# --- Predicate Methods ---

# @return true si c'est un mail-type
# Le traitement d'un mail type est tout à fait différent
# du traitement d'un mail de mailing
def mail_type?
  type == 'mail-type'
end

# @return true si un module ruby existe pour le mail
# @rappel
#   C'est un fichier qui porte le même affixe, mais avec '.rb' 
#   en extension.
# 
def module?
  File.exist?(module_path)
end

# @return true si le patronyme est requis dans le message
def require_patronyme?
  raw_message.match?(/\%\{patronyme\}/i)
end

# @return true si le sexe est requis dans le message
def require_feminines?
  defined?(REG_FEMININES) || begin
    SourceFile.const_set('REG_FEMININES', /\%\{(#{FEMININES['F'].keys.join('|')})\}/)
  end
  raw_message.match?(REG_FEMININES)
end

# --- Méthodes de traitement du message ---

# Méthode qui check que les métadonnées du fichier source soient bien
# valides (doit contenir les données minimales.
def data_valid_or_raise
  # metadata['to']        || raise('missing_to') # Plus obligatoire
  destinataires.nil? && metadata['to'].nil? && raise('missing_to')
  metadata['from']      || raise('missing_from')
  metadata['subject']   || raise('missing_subject')
  # Pour les mails type, le module est obligatoire (alors qu'il est
  # optionnel pour les mailings)
  if mail_type?
    File.exist?(module_path) || begin
      puts "Module attendu : #{module_path.inspect}".rouge
      raise('missing_data')
    end
  end
rescue Exception => e
  if ERRORS['source_file'].key?(e.message)
    raise InvalidDataError, "#{ERRORS['source_file']['invalid_metadata']} : #{ERRORS['source_file'][e.message]}"
  else
    puts e.message.rouge
    puts e.backtrace.join("\n").rouge if debug?
  end
end

def module_path
  @module_path ||= File.join(folder, "#{affixe}.rb")
end
def affixe
  @affixe ||= File.basename(path,File.extname(path))
end
def folder
  @folder ||= File.dirname(path)
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
  @metadata   = {}
  METADATA_NAMES.each { |n| @metadata.merge!(n => nil)}
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
