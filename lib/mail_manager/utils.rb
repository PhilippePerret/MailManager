module MailManager
class Utils
class << self

  def open_manuel(version_development = false)
    path = version_development ? MANUEL_MD_PATH : MANUEL_PDF_PATH
    `open "#{path}"`
  end

  MANUEL_MD_PATH  = File.expand_path(File.join(__dir__,'..','..',"Manual", "Manual-#{LANG}.md"))
  MANUEL_PDF_PATH = File.expand_path(File.join(__dir__,'..','..',"Manual", "Manual-#{LANG}.pdf"))

end #/<< self
end #/class Utils
end #/module MailManager
