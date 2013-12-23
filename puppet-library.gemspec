# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'puppet_library/version'

Gem::Specification.new do |spec|
  spec.name          = "puppet-library"
  spec.version       = PuppetLibrary::VERSION
  spec.authors       = ["drrb"]
  spec.email         = ["drrrrrrrrrrrb@gmail.com"]
  spec.description   = "A Puppet module server"
  spec.summary       = <<-EOF
    Puppet Library is a private Puppet module server that's compatible with librarian-puppet.
  EOF
  spec.homepage      = "https://github.com/drrb/puppet-library"
  spec.license       = "GPL-3"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "sinatra"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
