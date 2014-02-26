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
    describe "online proxy", :online => true do
        include ModuleSpecHelper

        let(:port) { Ports.next! }
        let(:project_dir) { Tempdir.create("project_dir") }
        let(:module_dir) { Tempdir.create("module_dir") }
        let(:cache_dir) { Tempdir.create("cache_dir") }
        let(:start_dir) { pwd }
        let(:proxy_server) do
            Server.configure do
                forge :directory do
                    path module_dir
                end
                forge :cache do
                    url "http://forge.puppetlabs.com"
                    path cache_dir
                end
            end
        end
        let(:proxy_rack_server) do
            Rack::Server.new(
                :app => proxy_server,
                :Host => "localhost",
                :Port => port,
                :server => "webrick"
            )
        end
        let(:proxy_server_runner) do
            Thread.new do
                proxy_rack_server.start
            end
        end

        before do
            # Initialize to catch wiring errors
            proxy_rack_server

            # Start the server
            proxy_server_runner
            start_dir
            cd project_dir
        end

        after do
            rm_rf module_dir
            rm_rf project_dir
            rm_rf cache_dir
            cd start_dir
        end

        it "services queries, downloads and searches through a proxy to a remote forge" do
            add_module("drrb", "tomcat", "1.0.0") do |metadata|
                metadata["dependencies"] << { "name" => "puppetlabs/apache", "version_requirement" => "0.9.0" }
            end

            write_puppetfile <<-EOF
                forge 'http://localhost:#{port}'
                mod 'drrb/tomcat'
            EOF

            # Install modules through the proxy
            system "librarian-puppet install" or fail "call to puppet-library failed"
            expect("tomcat").to be_installed
            expect("apache").to be_installed
            expect("concat").to be_installed
            expect("stdlib").to be_installed

            expect("puppetlabs-apache-*.tar.gz").to be_cached
        end
    end
end
