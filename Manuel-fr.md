# DataMail - Gestion des mails

## Prise en main rapide

~~~ruby
require 'mail_manager'


MailManager.send('/Users/phil/lemail.md')

~~~

Avec le fichier au chemin `path_mail_file` qui contient :

~~~markdown
# /Users/phil/lemail.md
---
from: philippe.perret@yahoo.fr
to:   phil@atelier-icare.net
---
Bonjour à toi, Phil,

Comment ça va ?

Phil

~~~

## Définition de la police et de la taille

Utiliser `font_family = ...` et `font_size = 14pt` dans les métadonnées.

Par défaut, la police est 'Times' et la taille est '14pt'.
