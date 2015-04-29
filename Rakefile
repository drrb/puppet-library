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
require 'json'
require 'yaml'
require 'net/http'

SUPPORTED_RUBY_VERSIONS = %w[1.8 1.9 2.0 2.1 system]
# Capybara needs Nokogiri, which needs 1.9+
ACCEPTANCE_TEST_INCOMPATIBLE_RUBY_VERSIONS = %w[1.8]

class String
    def green
        "\e[32m#{self}\e[0m"
    end

    def red
        "\e[31m#{self}\e[0m"
    end

    def yellow
        "\e[33m#{self}\e[0m"
    end
end

def ruby_version_supports_acceptance_tests?(version = RUBY_VERSION)
    ! ACCEPTANCE_TEST_INCOMPATIBLE_RUBY_VERSIONS.find do |bad_version|
        version.start_with? bad_version
    end
end

def offline?
    Net::HTTP.get_response(URI.parse("https://forgeapi.puppetlabs.com"))
    return false
rescue
    return true
end

if RUBY_VERSION.start_with? "1.8"
    namespace :coveralls do
        task :push do
            puts "Skipping Coverage pushing because this Ruby version doesn't support it"
        end
    end
else
    require 'coveralls/rake/task'
    Coveralls::RakeTask.new
end

desc "Run the specs"
RSpec::Core::RakeTask.new(:spec)

if ruby_version_supports_acceptance_tests?
    require 'cucumber/rake/task'
    Cucumber::Rake::Task.new(:features)
else
    task :features do
        puts "Skipping acceptance tests because this version of Ruby doesn't support them"
    end
end

desc "Run all the tests"
RSpec::Core::RakeTask.new(:test) do |rspec|
    rspec.pattern = "{spec,test}/**/*_{spec,integration_test}.rb"
end
task :test => :features

desc "Run the integration tests"
RSpec::Core::RakeTask.new(:integration_test) do |rspec|
    rspec.pattern = "test/**/*_integration_test.rb"
    tags = []
    tags << "~online" if offline?
    tags << "~no_1_8" if RUBY_VERSION.start_with? "1.8"
    unless tags.empty?
        rspec.rspec_opts = tags.map { |tag| "--tag #{tag}" }.join(" ")
    end
end

task :default => [:test, 'coveralls:push']

desc "Check it works on all local rubies"
task :verify => [ 'check-license', 'test-imports' ] do
    versions = SUPPORTED_RUBY_VERSIONS
    puts "\nRunning Specs".green
    spec_results = versions.map do |ruby_version|
        puts "\n- Ruby #{ruby_version}".green
        system "rvm #{ruby_version} do bundle exec rake spec"
    end

    puts "\nRunning Integration Tests".green
    integration_test_results = versions.map do |ruby_version|
        puts "\n- Ruby  #{ruby_version}".green
        system "rvm #{ruby_version} do bundle exec rake integration_test"
    end

    puts "\nRunning Acceptance Tests".green
    acceptance_test_results = versions.map do |ruby_version|
        puts "\n- Ruby  #{ruby_version}".green
        system "rvm #{ruby_version} do bundle exec rake features"
    end

    gem_versions = versions.map do |ruby_version|
        `rvm #{ruby_version} do gem --version`.strip
    end

    puts "\nResults:\n".green
    results = [ gem_versions, spec_results, integration_test_results, acceptance_test_results ].transpose
    puts "+---------+----------+-------+-------+-------+"
    puts "| Version | Gem Ver. | Specs |  ITs  |  ATs  |"
    puts "+---------+----------+-------+-------+-------+"
    versions.zip(results).each do |(version, (gem_version, spec_result, integration_test_result, acceptance_test_result))|
        v = version.ljust(7)
        g = gem_version.ljust(8)
        s = spec_result ? "pass".green : "fail".red
        i = integration_test_result ? "pass".green : "fail".red

        if ruby_version_supports_acceptance_tests? version
            a = acceptance_test_result ? "pass".green : "fail".red
        else
            a = "skip".yellow
        end
        puts "| #{v} | #{g} | #{s}  | #{i}  | #{a}  |"
    end
    puts "+---------+----------+-------+-------+-------+"

    versions.zip(results).each do |(version, (gem_version, spec_result, integration_test_result, acceptance_test_result))|
        unless spec_result
            fail "Specs failed with Ruby #{version}"
        end

        unless integration_test_result
            fail "Integration tests failed with Ruby #{version}"
        end

        unless acceptance_test_result
            fail "Acceptance tests failed with Ruby #{version}"
        end
    end
end

desc "Run simple checks"
task :check => [ "check-license", "test-imports" ]do
end

desc "Check all files for license headers"
task "check-license" do
    print "Checking that all program files contain license headers"

    files = `git ls-files`.split "\n"
    ignored_files = File.read(".licenseignore").split("\n") << ".licenseignore"
    offending_files = files.reject { |file| File.read(file).include? "WITHOUT ANY WARRANTY" } - ignored_files
    ok = offending_files.empty?
    result = if ok
        "OK".green
    else
        "FAIL".red
    end
    puts " [ #{result} ]"
    abort("ERROR: THE FOLLOWING FILES HAVE NO LICENSE HEADERS: \n" + offending_files.join("\n")) unless ok
end

desc "Print the version number"
task "version" do
    puts PuppetLibrary::VERSION
end

desc "Release Puppet Library"
task "push-release" => ["check-license", :verify] do
    puts "Releasing #{PuppetLibrary::VERSION}"
    Rake::Task[:release].invoke

    upload_release_notes(PuppetLibrary::VERSION)

    increment_version
    git_push
end

desc "Increment version number and commit it"
task "increment-version" do
    increment_version
end

desc "Register release with Github"
task "register-release", [:version] do |task, args|
    upload_release_notes(args[:version])
end

desc "Import files individually to make sure they can be imported externally"
task "test-imports" do
    puts "Testing imports:"
    Dir.chdir "lib" do
        paths = Dir["**/*.rb"].map {|f| f.sub /\.rb$/, "" }
        paths = paths.sort_by {|p| p.count "/"}
        errors = []
        paths.each do |path|
            print "importing #{path}..."
            output = `bundle exec ruby -e '$LOAD_PATH.unshift(File.expand_path(".")); require "#{path}"' 2>&1`
            print " ["
            if $?.success?
                print "OK".green
            else
                print "FAIL".red
                errors << "#{path}: #{output.red}"
            end
            puts "]"
        end

        unless errors.empty?
            puts
            puts
            fail <<-EOFAILURE
Failed to import some files:

#{errors.join "\n\n"}
            EOFAILURE
        end
    end
end

def upload_release_notes(version)
    puts "Registering release notes for #{version}"
    github = Github.new

    unless version =~ /\d+\.\d+\.\d+/
        raise "Bad version: '#{version}'"
    end
    unless system("git tag | grep v#{version} > /dev/null")
        raise "Couldn't find tag 'v#{version}'"
    end

    tag = "v#{version}"
    changelog = YAML.load_file(File.expand_path("CHANGELOG.yml", File.dirname(__FILE__)))
    release_notes = changelog.find {|release| release["tag"] == tag}
    changes = release_notes ? release_notes["changes"] : []
    description = changes.map { |change| "- #{change}" }.join("\n")
    data = {
        "tag_name" => tag,
        "target_commitish" => "master",
        "name" => "Version #{version}",
        "body" => description,
        "draft" => false,
        "prerelease" => false
    }
    release = github.get("/repos/drrb/puppet-library/releases").find {|release| release["tag_name"] == tag}
    if release
        puts "Release #{tag} exists. Updating it..."
        github.patch("/repos/drrb/puppet-library/releases/#{release['id']}", data)
    else
        puts "Creating release #{tag}..."
        github.post("/repos/drrb/puppet-library/releases", data)
    end
    puts "Done"
end

def git_push
    system "git push" or fail "Couldn't push release"
end

def increment_version
    major, minor, patch = PuppetLibrary::VERSION.split(".").map {|n| n.to_i}
    new_version = "#{major}.#{minor + 1}.0"
    puts "Updating version number to #{new_version}"
    system(%q[sed -i '' -E 's/VERSION = ".*"/VERSION = "] + new_version + %q["/' lib/puppet_library/version.rb]) or fail "Couldn't update version"
    PuppetLibrary::VERSION.replace new_version
    system "git commit lib/puppet_library/version.rb --message='[release] Incremented version number'" or fail "Couldn't commit new version number"
end

class Github
    def initialize
        @base_url = "https://api.github.com"
        api_key_file = File.expand_path("~/.github/release.apikey")
        raise "Put your github credentials in ~/.github/release.apikey as 'username:key'" unless File.exist? api_key_file
        @username, @key = File.read(api_key_file).strip.split ":"
    end

    def post(path, data, &block)
        puts "POST #{path}"
        request = Net::HTTP::Post.new(path)
        request.body = data.to_json
        send request
    end

    def patch(path, data, &block)
        puts "PATCH #{path}"
        request = Net::HTTP::Patch.new(path)
        request.body = data.to_json
        response = send(request, &block)
    end

    def get(path, &block)
        puts "GET #{path}"
        request = Net::HTTP::Get.new(path)
        send request
    end

    def send(request)
        request.add_field('Content-Type', 'application/json')
        request.basic_auth @username, @key

        uri = URI.parse(@base_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        response = http.request(request)
        puts response.code
        if block_given?
            yield(response)
        else
            unless response.code =~ /^2../
                raise "Request returned non-success:\n#{response.body}"
            end
            JSON.parse(response.body)
        end
    end
end
