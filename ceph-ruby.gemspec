# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ceph-ruby/version'

Gem::Specification.new do |gem|
  gem.name          = "ceph-ruby-ffi19"
  gem.version       = CephRuby::VERSION
  gem.authors       = ["Netskin GmbH", "Corin Langosch"]
  gem.email         = ["info@netskin.com", "info@corinlangosch.com"]
  gem.description   = %q{Easy management of Ceph}
  gem.summary       = %q{Easy management of Ceph Distributed Storage System using ruby}
  gem.homepage      = "https://github.com/ceph/ceph-ruby"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('ffi', '~> 1.9.10')
  gem.add_dependency('activesupport', '>= 3.0.0')
end
