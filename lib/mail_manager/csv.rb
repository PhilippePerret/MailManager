module MailManager
class CSV

  ##
  # Méthode qui permet de parser très profondément un fichier csv 
  # pour MailManager, en rejoignant même les clés étrangères
  # 
  def self.parse_all(path)
    rows = []
    csv_options = {headers: true, col_sep:','}
    ::CSV.read(path, **csv_options).each do |row|
      # puts "row = #{row}:#{row.class} (#{row.class.ancestors})"
      if row.to_s.start_with?('#')
        traite_as_comment_row(row)
      else
        rows << traite_as_data_row(row)
      end
    end
    return rows
  end

  def self.traite_as_comment_row(row)
    
  end

  def self.traite_as_data_row(row)
    row
  end

end #/class CSV
end #/module MailManager
