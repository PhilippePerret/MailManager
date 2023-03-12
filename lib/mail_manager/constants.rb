module MailManager

  GEM_LIB_FOLDER = File.expand_path(File.dirname(__dir__))
  GEM_FOLDER = File.dirname(GEM_LIB_FOLDER)
  TMP_FOLDER = mkdir(File.join(GEM_FOLDER,'tmp'))

  require '/Users/philippeperret/.secret/mail'
  DSMTP = MAILS_DATA[:smtp]
  SERVER_DATA = [DSMTP[:server],DSMTP[:port],DSMTP[:domain],DSMTP[:user_name],DSMTP[:password],:login]


  CLI.set_options_table({
    :s => :simulation,
    :e => :mail_errors, # pour renvoyer aux mails erronnés
    :d => :no_delay,
    :t => :test, # pour envoyer seulement à moi et marion
    :a => :admin, # pour envoyer seulement à l'administrateur
  })

  ADMINISTRATOR = {mail: 'philippe.perret@yahoo.fr', sexe:'H', prenom:'Phil', nom:'Perret', fonction:'Manager'}
  TEST_RECIPIENTS = [
    ADMINISTRATOR,
    {mail: 'marion.michel31@free.fr', sexe:'F', prenom:'Marion', nom:'MICHEL', fonction:'Assistante'}    
  ]


FEMININES = {
  'F' => {
    a:      'a',     # mon/m{a}
    e:      'e',     # fort/fort{e}
    eche:   'èche',  # sec/s{èche}
    elle:   'elle',
    ere:    'ère',
    ette:   'ette', # sujet/suj{ette}
    eve:    'ève',   # bref/br{ève}
    ine:    'ine',    # certa{in}/ certaine
    ne:     'ne',
    lle:    'lle',    # bel/be{lle}
    rice:   'rice',   # correcteur/correct{rice}
    se:     'se',     # heureux/heureuse
    sse:    'sse',    # maitre/maitre{sse}
    te:     'te',     # cet/cet{te}
    ve:     've',     # fautif/fauti{ve} | veuf/veu{ve}
  },
  'H' => {
    a:      'on',     # mon/m{a}
    e:      '',       # fort/fort{e}
    eche:   'ec',     # sec/s{èche}
    elle:   'il',
    ere:    'er',
    ette:   'et',     # sujet/suj{ette}
    eve:    'ef',     # bref/br{ève}
    ine:    'in',     # certa{in}/ certaine
    ne:     '',
    lle:    'l',      # bel/be{lle}
    rice:   'eur',    # correcteur/correct{rice}
    se:     'x',      # heureux/heureuse
    sse:    '',       # maitre/maitre{sse}
    te:     '',       # cet/cet{te}
    ve:     'f',      # fautif/fauti{ve} | veuf/veu{ve}
  }
}
end #/module MailManager
