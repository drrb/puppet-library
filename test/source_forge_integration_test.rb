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
        include ModuleSpecHelper

        let(:port) { Ports.next! }
        let(:module_dir) { Tempdir.new("module_dir") }
        let(:project_dir) { Tempdir.new("project_dir") }
        let(:start_dir) { pwd }
        let(:source_server) do
            Server.configure do
                forge :source do
                    path module_dir.path
                end
            end
        end
        let(:source_rack_server) do
            Rack::Server.new(
                :app => source_server,
                :Host => "localhost",
                :Port => port,
                :server => "webrick"
            )
        end
        let(:source_server_runner) do
            Thread.new do
                source_rack_server.start
            end
        end

        before do
            # Initialize to catch wiring errors
            source_rack_server

            # Start the servers
            source_server_runner
            start_dir
            cd project_dir.path
        end

        after do
            cd start_dir
        end

        it "services queries, downloads and searches from a directory containg a module's source" do
            add_file "Modulefile", <<-EOF
            name 'puppetlabs-ficticious'
            version '0.2.0'
            author 'puppetlabs'
            description 'Fake module'
            EOF

            write_puppetfile <<-EOF
                forge 'http://localhost:#{port}'
                mod 'puppetlabs/ficticious'
            EOF

            # Install modules
            system "librarian-puppet install" or fail "call to puppet-library failed"
            expect("ficticious").to be_installed

            # Search
            search_results = JSON.parse(open("http://localhost:#{port}/modules.json").read)
            found_modules = Hash[search_results.map do |result|
                [ result["full_name"], result["version"] ]
            end]
            expect(found_modules["puppetlabs/ficticious"]).to eq "0.2.0"

            # Download
            archive = open("http://localhost:#{port}/modules/puppetlabs-ficticious-0.2.0.tar.gz")
            expect(archive).to be_tgz_with /Modulefile/, /puppetlabs-ficticious/
            expect(archive).to be_tgz_with /metadata.json/, /"name":"puppetlabs-ficticious"/
        end
    end
end
