require_relative 'lib/mail_manager/version'

Gem::Specification.new do |s|
  s.name          = "mail-manager"
  s.version       = MailManager::VERSION
  s.authors       = ["PhilippePerret"]
  s.email         = ["philippe.perret@yahoo.fr"]

  s.summary       = %q{Gestion complète de l'envoi de mail}
  s.description   = %q{Gestion complet de mail, à partir d'un simple message en markdown, jusqu'au mailing, à partir de liste d'adresses quelconques.}
  s.homepage      = "https://github.com/PhilippePerret/MailManager"
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  s.metadata["allowed_push_host"] = "https://github.com/PhilippePerret/MailManager"

  s.add_dependency 'kramdown'
  s.add_dependency 'securerandom'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'minitest-color'

  s.metadata["homepage_uri"] = s.homepage
  s.metadata["source_code_uri"] = "https://github.com/PhilippePerret/MailManager"
  s.metadata["changelog_uri"] = "https://github.com/PhilippePerret/MailManager/CHANGELOG"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  s.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|features)/}) }
  end
  s.bindir        = "exe"
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]
end
