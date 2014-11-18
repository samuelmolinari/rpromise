# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rpromise/version'

Gem::Specification.new do |spec|
  spec.name          = "rpromise"
  spec.version       = Rpromise::VERSION
  spec.authors       = ["Samuel Molinari"]
  spec.email         = ["samuel@molinari.me"]
  spec.description   = %q{Handle async method easily}
  spec.summary       = %q{Handle async method easily}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "codeclimate-test-reporter"
end
