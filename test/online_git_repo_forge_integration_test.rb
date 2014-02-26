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
    describe "online git repo forge", :online => true do

        include ModuleSpecHelper

        let(:port) { Ports.next! }
        let(:project_dir) { Tempdir.create("project_dir") }
        let(:start_dir) { pwd }
        let(:git_server) do
            Server.configure do
                forge :git_repository do
                    source "https://github.com/puppetlabs/puppetlabs-stdlib.git"
                    include_tags /^[0-9.]+/
                end
            end
        end
        let(:git_rack_server) do
            Rack::Server.new(
                :app => git_server,
                :Host => "localhost",
                :Port => port,
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
                forge 'http://localhost:#{port}'
                mod 'puppetlabs/stdlib'
            EOF

            # Install modules
            system "librarian-puppet install --verbose" or fail "call to puppet-library failed"
            expect("stdlib").to be_installed

            # Search
            search_results = JSON.parse(open("http://localhost:#{port}/modules.json").read)
            stdlib_result = search_results.first
            expect(stdlib_result["full_name"]).to eq "puppetlabs/stdlib"
            expect(stdlib_result["releases"]).to include({"version"=>"4.0.2"})

            # Download
            archive = open("http://localhost:#{port}/modules/puppetlabs-stdlib-4.0.2.tar.gz")
            expect(archive).to be_tgz_with /Modulefile/, /puppetlabs-stdlib/
            expect(archive).to be_tgz_with /metadata.json/, /"name":"puppetlabs-stdlib"/
        end
    end
end
