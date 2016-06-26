# encoding: UTF-8
require File.expand_path("../lib/padrino/sprockets-version.rb", __FILE__)

Gem::Specification.new do |gem|
  gem.name = "padrino-sprockets"
  gem.version = Padrino::Sprockets::VERSION
  gem.description = "Padrino with Sprockets"
  gem.summary = gem.description
  gem.authors = ["Night Sailer, Matthias Günther", "James Tan"]
  gem.email = ["nightsailer@gmail.com, matthias.guenther@wikimatze.de, james@mercstudio.com"]
  gem.date = Time.now.strftime '%Y-%m-%d'
  gem.homepage = "https://github.com/nightsailer/padrino-sprockets"
  gem.licenses = ['MIT']
  gem.require_paths = ["lib"]
  gem.files = [
    'lib/padrino/tasks/*.rake',
    'lib/padrino/**/*.rb',
    'lib/padrino/*.rb'
    ]
  gem.add_dependency 'rake'
  gem.add_dependency 'sprockets', '~> 3.6.1'
  gem.add_dependency 'sprockets-helpers'
  gem.add_development_dependency "execjs", "~> 2.0"
  # gem.add_dependency 'coffee-script', '~> 2.4'
end
