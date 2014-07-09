# -*- encoding: utf-8 -*-
# Puppet Library
# Copyright (C) 2014 drrb
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'puppet_library/version'

Gem::Specification.new do |spec|
  spec.name          = "puppet-library"
  spec.version       = PuppetLibrary::VERSION
  spec.authors       = ["drrb"]
  spec.email         = ["drrrrrrrrrrrb@gmail.com"]
  spec.description   = "A private Puppet forge"
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
  spec.add_dependency "json"
  spec.add_dependency "haml"
  spec.add_dependency "docile", ">= 1.0.0"
  spec.add_dependency "open4"
  spec.add_dependency "redcarpet", "~> 2.3.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "rest-client", "~> 1.6.0"
  spec.add_development_dependency "gitsu"
  spec.add_development_dependency "librarian-puppet", "0.9.10" # 0.9.12 breaks on Ruby 1.8.7
  spec.add_development_dependency "mime-types", "< 2"
  spec.add_development_dependency "pry", "0.9.12.6"
  spec.add_development_dependency "puppet", "~> 3.3.0"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0.0"
  spec.add_development_dependency "simplecov"

  # Guard has dependencies that don't work with Ruby < 1.9
  unless RUBY_VERSION.start_with? "1.8"
      spec.add_development_dependency "guard"
      spec.add_development_dependency "guard-rspec"
      spec.add_development_dependency "terminal-notifier-guard"

      # Capybara needs Nokogiri, which needs 1.9+
      spec.add_development_dependency "capybara"
      spec.add_development_dependency "nokogiri" # Rubygems 1.8 fails to resolve this on Ruby 2.0.0
      spec.add_development_dependency "cucumber"
      spec.add_development_dependency "selenium-webdriver"
      spec.add_development_dependency "poltergeist"
  end
end
