Gem::Specification.new do |s|
  s.name        = 'pactrac'
  s.version     = '0.0.4'
  s.date        = '2012-09-11'
  s.summary     = "pactrac"
  s.description = "International package tracking for Ruby"
  s.authors     = ["Michael Alexander"]
  s.email       = 'beefsack@gmail.com'
  s.files       = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  s.executables << 'pactrac'
  s.require_path = 'lib'
  s.homepage    = 'https://github.com/Miniand/pactrac'
  s.add_dependency('nokogiri', '~> 1.5.5')
  s.add_dependency('commander', '~> 4.1.2')
  s.add_dependency('terminal-table', '~> 1.4.5')
  s.add_dependency('colorize', '~> 0.5.8')
end
