module MailManager

  GEM_LIB_FOLDER = File.expand_path(File.dirname(__dir__))
  GEM_FOLDER = File.dirname(GEM_LIB_FOLDER)

  require '/Users/philippeperret/.secret/mail'
  DSMTP = MAILS_DATA[:smtp]
  SERVER_DATA = [DSMTP[:server],DSMTP[:port],DSMTP[:domain],DSMTP[:user_name],DSMTP[:password],:login]


  CLI.set_options_table({
    s: :simulation
  })

FEMININES = {
  'F' => {
    a:      'a',     # mon/m{a}
    e:      'e',     # fort/fort{e}
    ere:    'ère',
    ne:     'ne',
    ette:   'ette', # sujet/suj{ette}
    elle:   'elle',
    lle:    'lle',  # bel/be{lle}
  },
  'H' => {
    a:      'on',     # mon/m{a}
    e:      '',      # fort/fort{e}
    ere:    'er',
    ne:     '',
    ette:   'et',    # sujet/suj{ette}
    elle:   'il',
    lle:    'l',     # bel/be{lle}
  }
}
end #/module MailManager
