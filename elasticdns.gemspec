Gem::Specification.new do |s|
  s.name        = 'elasticdns'
  s.version     = '0.0.5'
  s.date        = '2013-06-23'
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.summary     = "A simple bind9 configurator"
  s.description = "Elasticdns is a simple bind9 configurator"
  s.authors     = ["Gabriel Klein"]
  s.email       = 'gabriel.klein.fr@gmail.com'
  s.files       = `git ls-files`.split("\n")
  s.require_paths = ["lib"]
  s.homepage    = 'http://github.com/GabKlein/elasticdns'
  s.add_dependency('aws-sdk')
end
