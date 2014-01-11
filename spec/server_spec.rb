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

require "spec_helper"
require 'sinatra'
require 'rack/test'

module PuppetLibrary
    describe Server do
        include Rack::Test::Methods
        include ModuleSpecHelper
        include FileUtils

        let(:module_dir) { Tempfile.new("module_dir").path }
        let(:module_repo) { double(ModuleRepo) }
        let(:app) do
            Server.new(module_repo)
        end

        before do
            rm_rf module_dir
            mkdir_p module_dir
        end

        after do
            rm_rf module_dir
        end

        describe "GET /modules/<author>-<module>-<version>.tar.gz" do
            context "when the module is on the server" do
                before do
                    add_module("puppetlabs", "apache", "1.0.0")
                end
                it "serves the module" do
                    file_buffer = StringIO.new("module content")
                    expect(module_repo).to receive(:get_module).with("puppetlabs", "apache", "1.0.0").and_return(file_buffer)

                    get "/modules/puppetlabs-apache-1.0.0.tar.gz"

                    expect(last_response.body).to eq "module content"
                    expect(last_response.content_type).to eq "application/octet-stream"
                    expect(last_response.headers["Content-Disposition"]).to eq 'attachment; filename="puppetlabs-apache-1.0.0.tar.gz"'
                    expect(last_response).to be_ok
                end
            end

            context "when the module is not on the server" do
                it "returns an error" do
                    expect(module_repo).to receive(:get_module).with("puppetlabs", "apache", "1.0.0").and_return(nil)

                    get "/modules/puppetlabs-apache-1.0.0.tar.gz"

                    expect(last_response.content_type).to eq "application/octet-stream"
                    expect(last_response.status).to eq 404
                end
            end
        end

        describe "GET /<author>/<module>.json" do
            it "gets module metadata for all versions" do
                metadata = [ {
                    "author" => "puppetlabs",
                    "name" => "puppetlabs-apache",
                    "description" => "Apache module",
                    "version" => "1.0.0"
                }, {
                    "author" => "puppetlabs",
                    "name" => "puppetlabs-apache",
                    "description" => "Apache module",
                    "version" => "1.1.0"
                } ]
                expect(module_repo).to receive(:get_metadata).with("puppetlabs", "apache").and_return(metadata)

                get "/puppetlabs/apache.json"

                expect(last_response.body).to include('"author":"puppetlabs"')
                expect(last_response.body).to include('"full_name":"puppetlabs/apache"')
                expect(last_response.body).to include('"name":"apache"')
                expect(last_response.body).to include('"desc":"Apache module"')
                expect(last_response.body).to include('"releases":[{"version":"1.0.0"},{"version":"1.1.0"}]')
                expect(last_response).to be_ok
            end

            context "when no modules found" do
                it "returns an error" do
                    expect(module_repo).to receive(:get_metadata).with("nonexistant", "nonexistant").and_return([])

                    get "/nonexistant/nonexistant.json"

                    expect(last_response.body).to eq('{"error":"Could not find module \"nonexistant\""}')
                    expect(last_response.status).to eq(410)
                end
            end
        end

        describe "GET /api/v1/releases.json" do
            it "gets metadata for module and dependencies" do
                apache_metadata = [ {
                    "author" => "puppetlabs",
                    "name" => "puppetlabs-apache",
                    "description" => "Apache module",
                    "version" => "1.0.0",
                    "dependencies" => [
                        { "name" => "puppetlabs/stdlib", "version_requirement" => ">= 2.4.0" },
                        { "name" => "puppetlabs/concat", "version_requirement" => ">= 1.0.0" }
                    ]
                }, {
                    "author" => "puppetlabs",
                    "name" => "puppetlabs-apache",
                    "description" => "Apache module",
                    "version" => "1.1.0",
                    "dependencies" => [
                        { "name" => "puppetlabs/stdlib", "version_requirement" => ">= 2.4.0" },
                        { "name" => "puppetlabs/concat", "version_requirement" => ">= 1.0.0" }
                    ]
                } ]
                stdlib_metadata = [ {
                    "author" => "puppetlabs",
                    "name" => "puppetlabs-stdlib",
                    "description" => "Stdlib module",
                    "version" => "2.0.0",
                    "dependencies" => [ ]
                } ]
                concat_metadata = [ {
                    "author" => "puppetlabs",
                    "name" => "puppetlabs-concat",
                    "description" => "Concat module",
                    "version" => "1.0.0",
                    "dependencies" => [ ]
                } ]
                expect(module_repo).to receive(:get_metadata).with("puppetlabs", "apache").and_return(apache_metadata)
                expect(module_repo).to receive(:get_metadata).with("puppetlabs", "stdlib").and_return(stdlib_metadata)
                expect(module_repo).to receive(:get_metadata).with("puppetlabs", "concat").and_return(concat_metadata)

                get "/api/v1/releases.json?module=puppetlabs/apache"

                response = JSON.parse(last_response.body)
                expect(response.keys.sort).to eq(["puppetlabs/apache", "puppetlabs/concat", "puppetlabs/stdlib"])
                expect(response["puppetlabs/apache"].size).to eq(2)
                expect(response["puppetlabs/apache"][0]["file"]).to eq("/modules/puppetlabs-apache-1.0.0.tar.gz")
                expect(response["puppetlabs/apache"][0]["version"]).to eq("1.0.0")
                expect(response["puppetlabs/apache"][0]["version"]).to eq("1.0.0")
                expect(last_response).to be_ok
            end

            context "when the module can't be found" do
                it "returns an error" do
                    expect(module_repo).to receive(:get_metadata).with("nonexistant", "nonexistant").and_return([])

                    get "/api/v1/releases.json?module=nonexistant/nonexistant"

                    expect(last_response.body).to eq('{"error":"Module nonexistant/nonexistant not found"}')
                    expect(last_response.status).to eq(410)
                end
            end
        end
    end
end
