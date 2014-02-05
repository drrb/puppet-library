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
require 'open-uri'


module PuppetLibrary
    describe "librarian-puppet integration test" do
        include ModuleSpecHelper

        let(:module_dir) { Tempdir.create("module_dir") }
        let(:project_dir) { Tempdir.create("project_dir") }
        let(:cache_dir) { Tempdir.create("cache_dir") }
        let(:start_dir) { pwd }
        let(:disk_forge) { Forge::Directory.new(module_dir) }
        let(:disk_server) do
            Server.set_up do |server|
                server.forge disk_forge
            end
        end
        let(:disk_rack_server) do
            Rack::Server.new(
                :app => disk_server,
                :Host => "localhost",
                :Port => 9000,
                :server => "webrick"
            )
        end
        let(:disk_server_runner) do
            Thread.new do
                disk_rack_server.start
            end
        end
        let(:proxy_forge) { Forge::Cache.new("http://localhost:9000", cache_dir) }
        let(:proxy_server) do
            Server.set_up do |server|
                server.forge proxy_forge
            end
        end
        let(:proxy_rack_server) do
            Rack::Server.new(
                :app => proxy_server,
                :Host => "localhost",
                :Port => 9001,
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
            disk_rack_server
            proxy_rack_server

            # Start the servers
            disk_server_runner
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

        RSpec::Matchers.define :be_cached do
            match do |mod_file|
                File.exist?(File.join(cache_dir, mod_file))
            end
        end

        RSpec::Matchers.define :be_installed do
            match do |mod_name|
                File.directory?(File.join(project_dir, "modules",  mod_name))
            end
        end

        def write_puppetfile(content)
            File.open("#{project_dir}/Puppetfile", "w") do |puppetfile|
                puppetfile.puts content
            end
        end

        it "queries, downloads and searches through a proxy to a directory" do
            add_module("puppetlabs", "apache", "1.0.0") do |metadata|
                metadata["dependencies"] << { "name" => "puppetlabs/concat", "version_requirement" => ">= 2.0.0" }
                metadata["dependencies"] << { "name" => "puppetlabs/stdlib", "version_requirement" => "~> 3.0.0" }
            end
            add_module("puppetlabs", "concat", "2.0.0")
            add_module("puppetlabs", "stdlib", "3.0.0")

            write_puppetfile <<-EOF
                forge 'http://localhost:9001'
                mod 'puppetlabs/apache'
            EOF

            # Install modules through the proxy
            system "librarian-puppet install" or fail "call to puppet-library failed"
            expect("apache").to be_installed
            expect("concat").to be_installed
            expect("stdlib").to be_installed

            expect("puppetlabs-apache-1.0.0.tar.gz").to be_cached
            expect("puppetlabs-concat-2.0.0.tar.gz").to be_cached
            expect("puppetlabs-stdlib-3.0.0.tar.gz").to be_cached

            # Search through the proxy
            search_results = JSON.parse(open("http://localhost:9001/modules.json").read)
            found_modules = Hash[search_results.map do |result|
                [ result["full_name"], result["version"] ]
            end]
            expect(found_modules["puppetlabs/apache"]).to eq "1.0.0"
            expect(found_modules["puppetlabs/concat"]).to eq "2.0.0"
            expect(found_modules["puppetlabs/stdlib"]).to eq "3.0.0"
        end
    end
end
