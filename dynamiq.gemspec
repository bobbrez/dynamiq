# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dynamiq/version'

Gem::Specification.new do |spec|
  spec.name          = 'dynamiq'
  spec.version       = Dynamiq::VERSION
  spec.authors       = ['Bob Breznak']
  spec.email         = ['bob.breznak@gmail.com']
  spec.summary       = 'A dynamic priority queue extension for Sidekiq'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/bobbrez/dynamiq'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'sidekiq', '>= 3.0.0'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.add_development_dependency 'foreman', '~> 0.74.0'

  spec.add_development_dependency 'pry', '~> 0.10.0'
  spec.add_development_dependency 'pry-byebug', '~> 1.3.3'

  spec.add_development_dependency 'rspec', '~> 3.0.0'
  spec.add_development_dependency 'simplecov', '~> 0.9.0'
end
