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

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'coveralls/rake/task'

class String
    def green
        "\e[32m#{self}\e[0m"
    end

    def red
        "\e[31m#{self}\e[0m"
    end
end

if RUBY_VERSION =~ /^(1\.8|2\.1)/
    # The integration test doesn't work on Ruby 1.8.
    DEFAULT_TEST_TASK = :spec
else
    DEFAULT_TEST_TASK = :test
end

Coveralls::RakeTask.new

desc "Run the specs"
RSpec::Core::RakeTask.new(:spec)

desc "Run the integration tests"
RSpec::Core::RakeTask.new(:integration_test) do |rspec|
    rspec.pattern = "test/**/*_integration_test.rb"
end

desc "Run all the tests"
RSpec::Core::RakeTask.new(:test) do |rspec|
    rspec.pattern = "{spec,test}/**/*_{spec,integration_test}.rb"
end

task :default => [DEFAULT_TEST_TASK, 'coveralls:push']

desc "Check it works on all local rubies"
task :verify do
    versions = %w[1.8 1.9 2.0 2.1]
    puts "\nRunning Specs".green
    spec_results = versions.map do |ruby_version|
        puts "\n- Ruby #{ruby_version}".green
        system "rvm #{ruby_version} do rake spec"
    end

    puts "\nRunning Integration Tests".green
    integration_test_results = versions.map do |ruby_version|
        puts "\n- Ruby  #{ruby_version}".green
        system "rvm #{ruby_version} do rake integration_test"
    end

    puts "\nResults:\n".green
    results = spec_results.zip(integration_test_results)
    puts "+---------+-------+-------+"
    puts "| Version | Specs | Tests |"
    puts "+---------+-------+-------+"
    versions.zip(results).each do |(version, (spec_result, integration_test_result))|
        v = version
        s = spec_result ? "pass".green : "fail".red
        i = integration_test_result ? "pass".green : "fail".red
        puts "| #{v}     | #{s}  | #{i}  |"
    end
    puts "+---------+-------+-------+"
end

desc "Check all files for license headers"
task "check-license" do
    puts "Checking that all program files contain license headers"

    files = `git ls-files`.split "\n"
    ignored_files = File.read(".licenseignore").split("\n") << ".licenseignore"
    offending_files = files.reject { |file| File.read(file).include? "WITHOUT ANY WARRANTY" } - ignored_files
    if offending_files.empty?
        puts "Done"
    else
        abort("ERROR: THE FOLLOWING FILES HAVE NO LICENSE HEADERS: \n" + offending_files.join("\n"))
    end
end

desc "Print the version number"
task "version" do
    puts PuppetLibrary::VERSION
end

desc "Release Puppet Library"
task "push-release" => ["check-license", :verify] do
    puts "Releasing #{PuppetLibrary::VERSION}"
    Rake::Task[:release].invoke

    major, minor, patch = PuppetLibrary::VERSION.split(".").map {|n| n.to_i}
    new_version = "#{major}.#{minor + 1}.0"
    puts "Updating version number to #{new_version}"
    system(%q[sed -i '' -E 's/VERSION = ".*"/VERSION = "] + new_version + %q["/' lib/puppet_library/version.rb]) or fail "Couldn't update version"
    PuppetLibrary::VERSION.replace new_version
    system "git commit lib/puppet_library/version.rb --message='[release] Incremented version number'" or fail "Couldn't commit new version number"
end
