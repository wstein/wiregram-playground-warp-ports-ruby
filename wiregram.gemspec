# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'wiregram'
  spec.version = '0.1.0'
  spec.authors = ['WireGram Contributors']
  spec.email = ['contributors@wiregram.dev']

  spec.summary = 'WireGram - Ruby port from Crystal sources'
  spec.description = 'Lexer/Parser framework with support for multiple languages (Expression, JSON, UCL)'
  spec.homepage = 'https://github.com/wstein/wiregram-playground-warp-ports-ruby'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.files = Dir['lib/**/*.rb', 'bin/*', 'README.md', 'LICENSE']
  spec.bindir = 'bin'
  spec.executables = ['wiregram']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
end
