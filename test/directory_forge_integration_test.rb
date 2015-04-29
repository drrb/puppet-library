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
    describe "directory forge" do
        include ModuleSpecHelper

        let(:port) { Ports.next! }
        let(:module_dir) { Tempdir.new("module_dir") }
        let(:project_dir) { Tempdir.new("project_dir") }
        let(:start_dir) { pwd }
        let(:disk_server) do
            Server.configure do
                forge :directory do
                    path module_dir.path
                end
            end
        end
        let(:disk_rack_server) do
            Rack::Server.new(
                :app => disk_server,
                :Host => "localhost",
                :Port => port,
                :server => "webrick"
            )
        end
        let(:disk_server_runner) do
            Thread.new do
                disk_rack_server.start
            end
        end

        before do
            # Initialize to catch wiring errors
            disk_rack_server

            # Start the servers
            disk_server_runner
            start_dir
            cd project_dir.path
        end

        after do
            cd start_dir
        end

        it "services queries, downloads and searches from a directory" do
            add_module("puppetlabs", "apache", "1.0.0") do |metadata|
                metadata["dependencies"] << { "name" => "puppetlabs/concat", "version_requirement" => ">= 2.0.0" }
                metadata["dependencies"] << { "name" => "puppetlabs/stdlib", "version_requirement" => "3.x" }
            end
            add_module("puppetlabs", "concat", "2.0.0")
            add_module("puppetlabs", "stdlib", "3.0.0")

            write_puppetfile <<-EOF
                forge 'http://localhost:#{port}'
                mod 'puppetlabs/apache'
            EOF

            # Install modules
            system "librarian-puppet install" or fail "call to puppet-library failed"
            expect("apache").to be_installed
            expect("concat").to be_installed
            expect("stdlib").to be_installed

            # Search
            search_results = JSON.parse(open("http://localhost:#{port}/modules.json").read)
            found_modules = Hash[search_results.map do |result|
                [ result["full_name"], result["version"] ]
            end]
            expect(found_modules["puppetlabs-apache"]).to eq "1.0.0"
            expect(found_modules["puppetlabs-concat"]).to eq "2.0.0"
            expect(found_modules["puppetlabs-stdlib"]).to eq "3.0.0"
        end
    end
end
