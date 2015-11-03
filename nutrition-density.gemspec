# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nutrition/density/version'

Gem::Specification.new do |spec|
  spec.name          = "nutrition-density"
  spec.version       = Nutrition::Density::VERSION
  spec.authors       = ["Christian Köstlin"]
  spec.email         = ["christian.koestlin@esrlabs.com"]

  spec.summary       = %q{static sitegenerator that shows nutrition/calories.}
  spec.description   = %q{read http://www.drfuhrman.com/shop/ETLBook.aspx for more background information.}
  spec.homepage      = "http://gizmomogwai.github.io/nutrition-density/"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
