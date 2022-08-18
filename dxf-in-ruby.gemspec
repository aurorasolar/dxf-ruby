# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "dxf-in-ruby"
  gem.version       = '0.0.2'
  gem.authors       = ["Brandon Fosdick", "Meseker Yohannes"]
  gem.email         = ["meseker.yohannes@gmail.com"]
  gem.description   = %q{Read and write DXF files using Ruby}
  gem.summary       = %q{Tools for working with the popular DXF file format}
  gem.homepage      = "http://github.com/meseker/dxf-ruby"
  gem.required_ruby_version = ">= 2.7.5", "< 3.2"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency  'geometry-in-ruby'
  gem.add_dependency  'sketch'
  gem.add_dependency  'units-in-ruby'

  gem.add_development_dependency 'minitest'
end
