require "spec_helper"
require 'sinatra'
require 'rack/test'

module PuppetLibrary
    describe Server do
        include Rack::Test::Methods

        let(:module_repository) { double('module_repo') }
        let(:app) do
            Server.new
        end

        before do
            Server.set :repo, module_repository
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
                expect(module_repository).to receive(:get_metadata).with("puppetlabs", "apache").and_return(metadata)

                get "/puppetlabs/apache.json"

                expect(last_response).to be_ok
                expect(last_response.body).to include('"author":"puppetlabs"')
                expect(last_response.body).to include('"full_name":"puppetlabs/apache"')
                expect(last_response.body).to include('"name":"apache"')
                expect(last_response.body).to include('"desc":"Apache module"')
                expect(last_response.body).to include('"releases":[{"version":"1.0.0"},{"version":"1.1.0"}]')
            end

            context "when no modules found" do
                it "returns an error" do
                    expect(module_repository).to receive(:get_metadata).with("nonexistant", "nonexistant").and_return([])

                    get "/nonexistant/nonexistant.json"

                    expect(last_response.status).to eq(410)
                    expect(last_response.body).to eq('{"error":"Could not find module \"nonexistant\""}')
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
                expect(module_repository).to receive(:get_metadata).with("puppetlabs", "apache").and_return(apache_metadata)
                expect(module_repository).to receive(:get_metadata).with("puppetlabs", "stdlib").and_return(stdlib_metadata)
                expect(module_repository).to receive(:get_metadata).with("puppetlabs", "concat").and_return(concat_metadata)

                get "/api/v1/releases.json?module=puppetlabs/apache"

                expect(last_response).to be_ok
                response = JSON.parse(last_response.body)
                expect(response.keys).to eq(["puppetlabs/apache", "puppetlabs/stdlib", "puppetlabs/concat"])
                expect(response["puppetlabs/apache"].size).to eq(2)
                expect(response["puppetlabs/apache"][0]["file"]).to eq("/modules/puppetlabs-apache-1.0.0.tar.gz")
                expect(response["puppetlabs/apache"][0]["version"]).to eq("1.0.0")
                expect(response["puppetlabs/apache"][0]["version"]).to eq("1.0.0")
            end

            context "when the module can't be found" do
                it "returns an error" do
                    expect(module_repository).to receive(:get_metadata).with("nonexistant", "nonexistant").and_return([])

                    get "/api/v1/releases.json?module=nonexistant/nonexistant"

                    expect(last_response.status).to eq(410)
                    expect(last_response.body).to eq('{"error":"Module nonexistant/nonexistant not found"}')
                end
            end
        end
    end
end
