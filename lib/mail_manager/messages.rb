module MailManager

  LANG   = 'fr'
  ERRORS = YAML.load_file("#{GEM_LIB_FOLDER}/locales/#{LANG}/errors.yaml", **{symbolize_names:true})

end
