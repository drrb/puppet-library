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

require "spec_helper"
require 'sinatra'
require 'rack/test'

module PuppetLibrary
    describe Server do
        include Rack::Test::Methods

        let(:forge) { double(Forge) }
        let(:app) do
            Server.new(forge)
        end

        describe "GET /" do
            it "lists all the modules" do
                modules = [
                    {
                        "author" => "puppetlabs",
                        "name" => "apache",
                        "tag_list" => ["apache", "httpd"],
                        "releases" => [{"version"=>"0.0.1"}, {"version"=>"0.0.2"}],
                        "full_name" => "puppetlabs/apache",
                        "version" => "0.0.2",
                        "project_url" => "http://github.com/puppetlabs/puppetlabs-apache",
                        "desc" => "Puppet module for Apache"
                    }
                ]
                expect(forge).to receive(:search_modules).with(nil).and_return(modules)

                get "/"

                expect(last_response.body).to include "Modules"
                expect(last_response.body).to include "puppetlabs/apache"
                expect(last_response.body).to include "0.0.1"
                expect(last_response.body).to include "0.0.2"
            end

            context "when a search term is provided" do
                it "lists matching modules" do
                    modules = [
                        {
                            "author" => "puppetlabs",
                            "name" => "apache",
                            "tag_list" => ["apache", "httpd"],
                            "releases" => [{"version"=>"0.0.1"}, {"version"=>"0.0.2"}],
                            "full_name" => "puppetlabs/apache",
                            "version" => "0.0.2",
                            "project_url" => "http://github.com/puppetlabs/puppetlabs-apache",
                            "desc" => "Puppet module for Apache"
                        }
                    ]
                    expect(forge).to receive(:search_modules).with("apache").and_return(modules)

                    get "/?search=apache"

                    expect(last_response.body).to include "Modules"
                    expect(last_response.body).to include "puppetlabs/apache"
                    expect(last_response.body).to include "0.0.1"
                    expect(last_response.body).to include "0.0.2"
                end
            end
        end

        describe "GET /modules.json" do
            it "renders the search result as JSON" do
                search_results = [
                    {
                        "author" => "puppetlabs",
                        "name" => "apache",
                        "tag_list" => ["apache", "httpd"],
                        "releases" => [{"version"=>"0.0.1"}, {"version"=>"0.0.2"}],
                        "full_name" => "puppetlabs/apache",
                        "version" => "0.0.2",
                        "project_url" => "http://github.com/puppetlabs/puppetlabs-apache",
                        "desc" => "Puppet module for Apache"
                    }
                ]
                expect(forge).to receive(:search_modules).with("apache").and_return(search_results)

                get "/modules.json?q=apache"

                expect(last_response.body).to eq search_results.to_json
                expect(last_response).to be_ok
            end
        end

        describe "GET /modules/<author>-<module>-<version>.tar.gz" do
            context "when the module is on the server" do
                it "serves the module" do
                    file_buffer = StringIO.new("module content")
                    expect(forge).to receive(:get_module_buffer).with("puppetlabs", "apache", "1.0.0").and_return(file_buffer)

                    get "/modules/puppetlabs-apache-1.0.0.tar.gz"

                    expect(last_response.body).to eq "module content"
                    expect(last_response.content_type).to eq "application/octet-stream"
                    expect(last_response.headers["Content-Disposition"]).to eq 'attachment; filename="puppetlabs-apache-1.0.0.tar.gz"'
                    expect(last_response).to be_ok
                end
            end

            context "when the module is not on the server" do
                it "returns an error" do
                    expect(forge).to receive(:get_module_buffer).with("puppetlabs", "apache", "1.0.0").and_raise(Forge::ModuleNotFound)

                    get "/modules/puppetlabs-apache-1.0.0.tar.gz"

                    expect(last_response.content_type).to eq "application/octet-stream"
                    expect(last_response.status).to eq 404
                end
            end
        end

        describe "GET /<author>/<module>" do
            it "displays module metadata" do
                metadata = {
                    "author" => "puppetlabs",
                    "full_name" => "puppetlabs/apache",
                    "name" => "apache",
                    "desc" => "Puppet module for Apache",
                    "releases" => [
                        { "version" => "0.10.0" },
                        { "version" => "0.9.0" },
                    ]
                }
                expect(forge).to receive(:get_module_metadata).with("puppetlabs", "apache").and_return(metadata)

                get "/puppetlabs/apache"

                expect(last_response.body).to include "Author: puppetlabs"
                expect(last_response.body).to include "Name: apache"
                expect(last_response.body).to include "0.10.0"
                expect(last_response.body).to include "0.9.0"
                expect(last_response).to be_ok
            end

            context "when no modules found" do
                it "returns an error" do
                    expect(forge).to receive(:get_module_metadata).with("nonexistant", "nonexistant").and_raise(Forge::ModuleNotFound)

                    get "/nonexistant/nonexistant"

                    expect(last_response.body).to include 'Module "nonexistant/nonexistant" not found'
                    expect(last_response.status).to eq(404)
                end
            end
        end

        describe "GET /<author>/<module>.json" do
            it "gets module metadata for all versions" do
                metadata = {
                    "author" => "puppetlabs",
                    "full_name" => "puppetlabs/apache",
                    "name" => "apache",
                    "desc" => "Puppet module for Apache",
                    "releases" => [
                        { "version" => "0.10.0" },
                        { "version" => "0.9.0" },
                    ]
                }
                expect(forge).to receive(:get_module_metadata).with("puppetlabs", "apache").and_return(metadata)

                get "/puppetlabs/apache.json"

                expect(last_response.body).to eq metadata.to_json
                expect(last_response).to be_ok
            end

            context "when no modules found" do
                it "returns an error" do
                    expect(forge).to receive(:get_module_metadata).with("nonexistant", "nonexistant").and_raise(Forge::ModuleNotFound)

                    get "/nonexistant/nonexistant.json"

                    expect(last_response.body).to eq('{"error":"Could not find module \"nonexistant\""}')
                    expect(last_response.status).to eq(410)
                end
            end
        end

        describe "GET /api/v1/releases.json" do
            it "gets metadata for module and dependencies" do
                metadata = {
                    "puppetlabs/apache" => [
                        {
                            "file" => "/system/releases/p/puppetlabs/puppetlabs-apache-0.9.0.tar.gz",
                            "version" => "0.9.0",
                            "dependencies" => [
                                [ "puppetlabs/concat", ">= 1.0.0" ],
                                [ "puppetlabs/stdlib", ">= 2.4.0" ]
                            ]
                        }
                    ],
                    "puppetlabs/stdlib" => [
                        {
                            "file" => "/system/releases/p/puppetlabs/puppetlabs-stdlib-3.0.0.tar.gz",
                            "version" => "3.0.0",
                            "dependencies" => [ ]
                        }
                    ],
                    "puppetlabs/concat" => [
                        {
                            "file" => "/system/releases/p/puppetlabs/puppetlabs-concat-1.0.0-rc1.tar.gz",
                            "version" => "1.0.0-rc1",
                            "dependencies" => [ ]
                        }
                    ]
                }
                expect(forge).to receive(:get_module_metadata_with_dependencies).with("puppetlabs", "apache", nil).and_return(metadata)

                get "/api/v1/releases.json?module=puppetlabs/apache"

                expect(last_response.body).to eq metadata.to_json
                expect(last_response).to be_ok
            end

            context "when the module can't be found" do
                it "returns an error" do
                    expect(forge).to receive(:get_module_metadata_with_dependencies).with("nonexistant", "nonexistant", nil).and_raise(Forge::ModuleNotFound)

                    get "/api/v1/releases.json?module=nonexistant/nonexistant"

                    expect(last_response.body).to eq('{"error":"Module nonexistant/nonexistant not found"}')
                    expect(last_response.status).to eq(410)
                end
            end

            context "when a version is specified" do
                it "looks up the specified version" do
                    expect(forge).to receive(:get_module_metadata_with_dependencies).with("puppetlabs", "apache", "1.0.0")

                    get "/api/v1/releases.json?module=puppetlabs/apache&version=1.0.0"
                end
            end
        end
    end
end
