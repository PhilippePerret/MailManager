module MailManager
class Message

  # = main =
  # 
  # Traitement du message pour un mail-type
  # 
  def traited_code_as_mail_type

    data_path = if source_file.data.start_with?('/') && File.exist?(source_file.data)
      source_file.data
    else
      File.expand_path(File.join('.',source_file.data))
    end
    puts "Module data : #{data_path.inspect}"
    # 
    # On requiert le fichier module data
    # 
    require data_path
    # 
    # On remplace les textes
    # 
    self.class.include MailTypeModule
    code = evaluate_mail_type(raw_code)
    source_file.subject = evaluate_mail_type(source_file.subject)

    # 
    # Les transformations normale
    # TODO : peut-être qu'on pourrait juste ajouter le traitement
    # ci-dessus au traitement des mailings ?
    # 
    code_html = kramdown(code).strip
    @plain_text = code_html.dup
    code_html = traite_table_in_kramdown_code(code_html)
    code_html = rowize_kramdown_code(code_html)
    code_html = remplace_images_in(code_html)
    # - Il faut absolument terminer par : -
    remplace_variables_in(code_html)
  rescue TTY::Reader::InputInterrupt
    raise e
  rescue Exception => e
    puts e.message.rouge
    puts e.backtrace.join("\n").rouge
    exit(100)
  end

  def evaluate_mail_type(c)
    c.gsub(/\#\{(.+?)\}/) do
      begin
        v1 = $1.freeze
        eval(v1)
      rescue Exception => e
        puts e.message.rouge
        puts "Le module MailTypeModule doit définir #{v1.inspect}"
        puts "[INCONNU: #{v1}]".rouge
        puts e.backtrace.join("\n").rouge
        exit(1)
      end
    end
  end


end #/class Message
end #/module MailManager
