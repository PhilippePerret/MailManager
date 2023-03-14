=begin
  
  class MailManager::Recipient
  ----------------------------
  Gestion des destinataires

=end
require 'csv'
module MailManager
class Recipient

###################       CLASSE      ###################
class << self

attr_reader :source_file

# @return [Array<MailManager::Recipient>] La liste des
# destinataires, même lorsqu'il n'y en a qu'un seul.
# 
# @param [String] str SOIT un path vers un fichier contenant les destinataires (csv)
#                     SOIT un mail seul (quand exclusion par exemple)
#                     SOIT un "patronyme <email>"
#                     SOIT une liste (string) de mails ou de patronyme
# @param [MailManager::SourceFile] srcfile Fichier source définissant entièrement l'envoi
# @param [Hash] options
# @option options [Boolean] :only_mail Si true, seul le mail est requis pour que le destinataire soit valide (liste d'exclusions)
# (pour le moment, toutes les autres données — qui correspondent aux
#  méta données — sont inutilisées)
# 
def destinataires_from(str, srcfile, **options)
  @source_file = srcfile
  if File.exist?(str)
    # <= Un fichier
    # => C'est une liste de destinataires
    load(str, **options)
  elsif str.match?(/^\[(.+)\]$/)
    traite_as_recipients_list(eval(str), **options)
  elsif str.match?('@')
    # <= Contient l'arobase
    # => C'est une adresse mail ou liste
    [new(str, **options)]
  end
end


# Méthode qui charge une liste de destinataires à partir d'un
# fichier CSV ou YAML
# 
# @note
#   L'existence doit être vérifiée avant.
# 
# @param [String] fpath   Chemin d'accès au fichier CSVde destinataires
# @param [Hash] options   Cf. #destinataires_from ci-dessus
# 
def load(fpath, **options)
  case File.extname(fpath).downcase
  when '.csv'
    options = {headers:true, col_sep:','}
    CSV.read(fpath, **options).reject{|line|line.start_with?('# ')}
  when '.yaml'
    YAML.load_file(fpath)
  else
    raise BadListingError, ERRORS['listing']['bad_extension'] % File.extname(fpath).downcase
  end.map do |ddest|
    new(ddest, **options)
  end
end

# Traitement d'une liste de destinataires définis en dur dans
# l'entête du mail
def traite_as_recipients_list(liste, **options)
  liste.map { |dst| new(dst, **options) }
end
  
end #/<< self
###################       INSTANCE      ###################
  
  attr_reader :mail
  attr_reader :options


  BASE_REG_MAIL = /((?:[a-zA-Z0-9._\-]+)@(?:[^ .,]+)\.[a-zA-Z]{2,10})/
  REG_MAIL = /^#{BASE_REG_MAIL}$/
  REG_MAIL_AND_PATRO = /^(.+?)<#{BASE_REG_MAIL}>$/

  # Instanciation d'un destinataire.
  # Peut être instancié par :
  #   - un string : l'adresse mail seule
  #   - un string : une ligne de donnée d'un fichier csv
  #   - un hash : les données :mail, :patronyme, etc.
  # 
  # @param [String] designation Cf. ci-dessus
  # @param [Hash] options
  # @option options [Boolean] :only_mail  Si TRUE, seul le mail est nécessaire pour valider le destinataire (exclusion de destinataire par son mail)
  def initialize(designation, **options)
    @options    = options
    @data       = {}
    @fonction   = nil
    @mail       = nil
    @sexe       = nil
    @patronyme  = nil
    # 
    # Étude de la désignation pour prendre les données
    # 
    case designation
    when REG_MAIL_AND_PATRO
      dre = designation.match(REG_MAIL_AND_PATRO)
      @mail = dre[2].strip
      @patronyme = dre[1].strip
    when REG_MAIL
      @mail       = designation
      @patronyme  = nil
    when BASE_REG_MAIL
      # - La donnée contient un mail, mais pas seulement, ni 
      #   seulement un patronyme. En fait, le recipient est 
      #   defini à l'aide d'un triptyque "sexe,mail,patronyme" 
      #   dans n'importe quel ordre -
      traite_as_triolet(designation)
    when String
      raise ERRORS['mail']['invalid'] % designation
    when Hash
      dispatch_data(designation)
    when CSV::Row
      dispatch_data(designation.to_hash)
    else
      raise "Je ne sais pas comment traiter une désignation de classe #{designation.class.inspect}."
    end
    #
    # Vérification de la validité des informations sur le destina-
    # taire en fonction du contexte
    # 
    check_if_valid
    # - Toujours passer le mail en minuscules -
    @mail = @mail.strip.downcase
  end
  # /instanciate

  def inspect
    @inspect ||= "#{patronyme} (#{mail})"
  end

  def check_if_valid
    des = designation.inspect
    not(@mail.nil?) || raise(InvalidDataError, ERRORS['recipient']['require_mail'] % des)
    unless options[:only_mail]
      if self.class.source_file.require_patronyme?
        not(patronyme.nil?) || raise(InvalidDataError, ERRORS['recipient']['require_patronyme'] % des)
      end
      if self.class.source_file.require_feminines?
        not(@sexe.nil?) || raise(InvalidDataError, ERRORS['recipient']['require_sexe'] % des)
      end
    end
  end

  # @return [String] L'adresse à écrire dans le mail
  def as_to
    str = mail
    str = "#{patronyme} <#{mail}>" if patronyme
    return str
  end

  def as_hash
    @data.merge({
      mail:       mail,
      prenom:     prenom,
      nom:        nom,
      patronyme:  patronyme,
      sexe:       sexe,
      fonction:   fonction
    })
  end

  # --- Données du destinataire ---

  def patronyme ; @patronyme  || patronyme_from_prenom_nom end
  def patronyme_from_prenom_nom
    if prenom && nom
      "#{prenom} #{nom}".strip
    end
  end
  def sexe      ; @sexe       || 'H' end
  def fonction  ; @fonction   end
  def prenom
    @firstname ||= @prenom ||= begin
      get_prenom_from_patronyme if @patronyme
    end
  end
  def nom
    @nom ||= begin
      @lastname ||= @nom ||= begin
        get_nom_from_patronyme if @patronyme
      end
    end    
  end


  # --- Predicate Methods ---

  def femme?
    :TRUE == @isfemme ||= true_or_false(sexe == 'F')
  end

  def homme?
    :TRUE == @ishomme ||= true_or_false(not(femme?))
  end

private


  def dispatch_data(drec)
    drec.each do |k, v|
      if k.nil?
        puts "Une clé de la table des destinataires est nil, dans #{drec.inspect}.".rouge
        puts "Il manque certainement une définition de colonne dans le fichier csv.".rouge
        puts "Corriger le problème puis relancer le mailing.".orange
        exit(100)
      end
      begin
        k = k.to_s.downcase
        v = v.strip unless v.nil?
        self.instance_variable_set("@#{k}", v)
        @data.merge!(k => v)
      rescue Exception => e
        puts "Problème avec k = #{k.inspect} et v = #{v.inspect}".rouge
        puts "Donnée complète : #{drec.inspect}".rouge
        puts "Erreur : #{e.message}".rouge
        exit(100)
      end
    end
  end


  # Traite la donnée donnée à l'instanciation comme un "triolet",
  # c'est-à-dire un String qui peut définir le patronyme, le mail et
  # le sexe, mais dans n'importe quel ordre.
  # La seule contrainte : que les données soient séparées par des
  # virgules
  def traite_as_triolet(str)
    str.split(',').each do |seg|
      seg = seg.strip
      if seg.match?(REG_MAIL)
        @mail = seg
      elsif seg == 'H' || seg == 'F'
        @sexe = seg
      else
        @patronyme = seg
      end
    end
  end


  def get_nom_from_patronyme
    return nil if patronyme.nil?
    decompose_patronyme
    @nom
  end
  def get_prenom_from_patronyme
    return nil if patronyme.nil?
    decompose_patronyme
    @prenom
  end
  def decompose_patronyme
    segs = patronyme.split(' ')
    if segs.count == 2
      @prenom, @nom = segs
    else
      sprenom = []
      snom    = []
      segs.each do |seg|
        if seg.match?(/[^A-ZÀÄÂÉÈÊÎÏÔÇÙ\-]/)
          sprenom << seg
        else
          snom << seg
        end
      end
      @prenom = sprenom.join(' ')
      @nom    = snom.join(' ')
    end
  end

end #/class Recipient
end #/module MailManager
