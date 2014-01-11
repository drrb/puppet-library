# -*- encoding: utf-8 -*-
# Puppet Library
# Copyright (C) 2013 drrb
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

include FileUtils

module PuppetLibrary
    describe "librarian-puppet integration test" do
        include ModuleSpecHelper

        let(:module_dir) { Tempfile.new("module_dir").path }
        let(:project_dir) { Tempfile.new("project_dir").path }
        let(:start_dir) { pwd }
        let(:repo) { ModuleRepo::Directory.new(module_dir) }
        let(:server) {
            Server.new(repo)
        }
        let(:rack_server) do
            Rack::Server.new(
                :app => server,
                :Host => "localhost",
                :Port => 9000
            )
        end
        let(:server_runner) do
            Thread.new do
                rack_server.start
            end
        end

        before do
            rm_rf module_dir
            rm_rf project_dir
            mkdir_p module_dir
            mkdir_p project_dir
            server_runner
            sleep(2) # Wait for the server to start
            start_dir
            cd project_dir
        end

        after do
            rm_rf module_dir
            rm_rf project_dir
            cd start_dir
        end

        def write_puppetfile(content)
            File.open("#{project_dir}/Puppetfile", "w") do |puppetfile|
                puppetfile.puts content
            end
        end

        it "downloads the modules" do
            add_module("puppetlabs", "apache", "1.0.0") do |metadata|
                metadata["dependencies"] << { "name" => "puppetlabs/concat", "version_requirement" => ">= 2.0.0" }
                metadata["dependencies"] << { "name" => "puppetlabs/stdlib", "version_requirement" => "~> 3.0.0" }
            end
            add_module("puppetlabs", "concat", "2.0.0")
            add_module("puppetlabs", "stdlib", "3.0.0")

            write_puppetfile <<-EOF
                forge 'http://localhost:9000'
                mod 'puppetlabs/apache'
            EOF

            system "librarian-puppet install" or fail "call to puppet-library failed"
            expect(File.directory? "modules").to be true
            expect(File.directory? "modules/apache").to be true
            expect(File.directory? "modules/concat").to be true
            expect(File.directory? "modules/stdlib").to be true
        end
    end
end
