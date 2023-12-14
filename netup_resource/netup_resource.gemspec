$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "netup_resource/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "netup_resource"
  s.version     = NetupResource::VERSION
  s.authors     = ["Michael Roeder", "Markus Kuerzinger", "Fabian Zitter"]
  s.email       = ["support@net-up.de"]
  s.homepage    = "http://www.net-up.de"
  s.summary     = "Summary of NetupResource."
  s.description = "RoR Restful Webservice Object Mapper Plugin

Beschreibung

Ein Plugin für das Web-Framework Ruby on Rails, welches dem Anwender erlaubt mit APIs zu kommunizieren, als würde man per ORM auf eine Datenbank zugreifen. Das Plugin benötigt allgemein nicht einmal ein schema für die entsprechende Schnittstelle, da es die Objekte automatisiert und dynamisch n-Dimensional erzeugen kann. Jedoch ist es auch möglich, ein Schema im Model oder per YAML File zu definieren.

Grundlegend funktioniert das Mappen, indem man Model-Klassen erstellt und diese von der Basis-Klasse des Plugins (statt von ActiveRecord::Base) erben lässt. Dem Model stehen dann die gängigen 4 Rest-Calls als statische Methoden zur Verfügung. (get,post,put,delete)

Die wenigen, nötigen Konfigurationen finden jeweils im Klassen-Korpus der Modelklasse statt. (siehe Doku)"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "< 8"

  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "webmock"
end
