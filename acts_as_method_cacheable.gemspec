# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'acts_as_method_cacheable/version'

Gem::Specification.new do |spec|
  spec.name          = "acts_as_method_cacheable"
  spec.version       = ActsAsMethodCacheable::VERSION
  spec.authors       = ["Ben Cao"]
  spec.email         = ["benb88@gmail.com"]
  spec.description   = "Make cache methods on ActiveRecord easy!"
  spec.summary       = "Instead of writing def expensive { @cached_expensive ||= original_expensive }, now you can write instance.cache_method(:expensive) instead. Also support nested cache method for associations."
  spec.homepage      = "https://github.com/bencao/acts_as_method_cacheable"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10.0.4"
  spec.add_development_dependency "rspec", "~> 2.13.0"
  spec.add_development_dependency "mocha", "~> 0.13.3"
  spec.add_development_dependency "sqlite3", "~> 1.3.7"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-theme"
  spec.add_development_dependency "pry-nav"
  spec.add_dependency "activesupport", "~> 3.2.13"
  spec.add_dependency "activerecord", "~> 3.2.13"
end
