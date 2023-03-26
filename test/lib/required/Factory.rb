=begin

  Fichier source (MailManager::SourceFile)
  ----------------------------------------
  
  Factory.source_file(**options)
    @return [MailManager::SourceFile] une instance de fichier source
    @option options[:name]    Nom du fichier dans test/assets/

  Factory.source_file_path(name)
    @return [String] Chemin d'accès au fichier source de nom +name+
    @param [String] name Nom du fichier (doit exister)

  Factory.build_source_file(data)
    Construction d'un fichier source
    @return [String] Le chemin d'accès au fichier
    @param [Hash] data Les données
    @option data [String] :name   Le nom du fichier
    @option data [String] :message  Le message à envoyer
    @option data [Hash] :metadata   Table des métadonnées

=end
require_relative 'Factory_image'
class Factory
###################      CLASS       ###################
class << self

  def source_file(options = {})
    if options.is_a?(String)
      options = {name: options}
    end
    options.key?(:name) || options.merge!(name: 'simple')
    path = source_file_path(options[:name])
    MailManager::SourceFile.new(path)
  end

  def source_file_path(name)
    File.expand_path("./test/assets/source_files/#{name}.md")
  end

  def build_source_file(data)
    metadata = data[:metadata].map do |k,v| 
      next if v.nil?
      "#{k} = #{v}" 
    end.compact.join("\n")
    srcpath = source_file_path(data[:name] || 'custom')
    File.write(srcpath, <<~TEXT)
    ---
    #{metadata}
    ---
    #{data[:message] || "Un message de mail"}
    TEXT
    return srcpath    
  end
end #/<< self
end #/class Factory
