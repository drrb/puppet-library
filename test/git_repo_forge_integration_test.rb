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

require 'spec_helper'
require 'integration_test_helper'
require 'open-uri'

module PuppetLibrary
    describe "source forge" do
        @@repo_path = Tempdir.create("git-repo")
        @@versions = [ "0.9.0", "1.0.0-rc1", "1.0.0" ]
        @@tags = @@versions + [ "xxx" ]

        before :all do
            def git(command)
                git_command = "git --git-dir=#{@@repo_path}/.git --work-tree=#{@@repo_path} #{command}"
                `#{git_command}`
                unless $?.success?
                    raise "Failed to run command: \"#{git_command}\""
                end
            end

            git "init"
            git "config user.name tester"
            git "config user.email tester@example.com"
            @@versions.zip(@@tags).each do |(version, tag)|
                File.open(File.join(@@repo_path, "Modulefile"), "w") do |modulefile|
                    modulefile.write <<-MODULEFILE
                    name 'puppetlabs-apache'
                    version '#{version}'
                    author 'puppetlabs'
                    MODULEFILE
                end
                git "add ."
                git "commit --message='Version #{version}'"
                git "tag #{tag}"
            end
        end

        after :all do
            rm_rf @@repo_path
        end

        include ModuleSpecHelper

        let(:project_dir) { Tempdir.create("project_dir") }
        let(:start_dir) { pwd }
        let(:git_forge) { Forge::GitRepository.new("puppetlabs", "apache", /^[0-9.]+/, @@repo_path) }
        let(:git_server) do
            Server.set_up do |server|
                server.forge git_forge
            end
        end
        let(:git_rack_server) do
            Rack::Server.new(
                :app => git_server,
                :Host => "localhost",
                :Port => 9003,
                :server => "webrick"
            )
        end
        let(:git_server_runner) do
            Thread.new do
                git_rack_server.start
            end
        end

        before do
            # Initialize to catch wiring errors
            git_rack_server

            # Start the servers
            git_server_runner
            start_dir
            cd project_dir
        end

        after do
            rm_rf project_dir
            cd start_dir
        end

        it "services queries, downloads and searches from a git repository" do
            write_puppetfile <<-EOF
                forge 'http://localhost:9003'
                mod 'puppetlabs/apache'
            EOF

            # Install modules
            system "librarian-puppet install" or fail "call to puppet-library failed"
            expect("apache").to be_installed

            # Search
            search_results = JSON.parse(open("http://localhost:9003/modules.json").read)
            apache_result = search_results.first
            expect(apache_result["full_name"]).to eq "puppetlabs/apache"
            expect(apache_result["releases"]).to eq [{"version"=>"1.0.0"}, {"version"=>"1.0.0-rc1"}, {"version"=>"0.9.0"}]

            # Download
            archive = open("http://localhost:9003/modules/puppetlabs-apache-0.9.0.tar.gz")
            expect(archive).to be_tgz_with /Modulefile/, /puppetlabs-apache/
            expect(archive).to be_tgz_with /metadata.json/, /"name":"puppetlabs-apache"/
        end
    end
end
