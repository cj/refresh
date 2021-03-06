# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'refresh/version'

Gem::Specification.new do |spec|
  spec.name          = "refresh"
  spec.version       = Refresh::VERSION
  spec.authors       = ["cj"]
  spec.email         = ["cjlazell@gmail.com"]
  spec.summary       = %q{auto refresh/reload your ruby code/site}
  spec.description   = %q{auto refresh/reload your ruby code/site}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "listen"
  spec.add_dependency "unicorn"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
