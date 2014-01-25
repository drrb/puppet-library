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

module PuppetLibrary::Forge
    describe Proxy do
        let(:http_client) { double('http_client') }
        let(:query_cache) { PuppetLibrary::Http::Cache::InMemory.new }
        let(:download_cache) { PuppetLibrary::Http::Cache::InMemory.new }
        let(:forge) { Proxy.new("http://puppetforge.example.com", query_cache, download_cache, http_client) }

        describe "url" do
            it "defaults to HTTP, when protocol not specified" do
                forge = Proxy.new("forge.puppetlabs.com", query_cache, download_cache, http_client) 

                expect(http_client).to receive(:get).with("http:\/\/forge.puppetlabs.com/puppetlabs/apache.json").and_return('{"puppetlabs/apache":[]}')

                forge.get_module_metadata("puppetlabs", "apache")
            end

            it "copes with a trailing slash" do
                forge = Proxy.new("forge.puppetlabs.com/", query_cache, download_cache, http_client) 

                expect(http_client).to receive(:get).with("http:\/\/forge.puppetlabs.com/puppetlabs/apache.json").and_return('{"puppetlabs/apache":[]}')

                forge.get_module_metadata("puppetlabs", "apache")
            end
        end

        describe "#search_modules" do
            it "forwards the request directly" do
                search_results = '["a","b","c"]'
                expect(http_client).to receive(:get).
                    with("http://puppetforge.example.com/modules.json?q=apache").
                    and_return(search_results)

                result = forge.search_modules("apache")
                expect(result).to eq JSON.parse(search_results)
            end

            it "caches the results" do
                search_results = '["a","b","c"]'
                expect(http_client).to receive(:get).once.
                    with("http://puppetforge.example.com/modules.json?q=apache").
                    and_return(search_results)

                forge.search_modules("apache")
                forge.search_modules("apache")
            end

            context "when the query is nil" do
                it "doesn't forward it as a request parameter" do
                    expect(http_client).to receive(:get).
                        with("http://puppetforge.example.com/modules.json").
                        and_return("[]")

                    forge.search_modules(nil)
                end
            end
        end

        describe "#get_module_buffer" do
            context "module version not found" do
                it "raises an error" do
                    expect(http_client).to receive(:get).
                        with("http://puppetforge.example.com/api/v1/releases.json?module=puppetlabs/apache").
                        and_raise(OpenURI::HTTPError.new("404 Not Found", "Module not found"))

                    expect {
                        forge.get_module_buffer("puppetlabs", "apache", "1.0.0")
                    }.to raise_error ModuleNotFound
                end
            end

            context "when there is an error downloading the archive" do
                it "raises an error" do
                    expect(http_client).to receive(:get).
                        with("http://puppetforge.example.com/api/v1/releases.json?module=puppetlabs/apache").
                        and_return('{"puppetlabs/apache":[{"version":"1.0.0","file":"/puppetlabs/apache.tgz","dependencies":[["puppetlabs/concat",">= 1.0.0"],["puppetlabs/stdlib","~> 2.0.0"]]},{"version":"2.0.0","dependencies":[]}]}')
                    expect(http_client).to receive(:download).
                        with("http://puppetforge.example.com/puppetlabs/apache.tgz").
                        and_raise(OpenURI::HTTPError.new("404 Not Found", "Module not found"))

                    expect {
                        forge.get_module_buffer("puppetlabs", "apache", "1.0.0")
                    }.to raise_error ModuleNotFound
                end
            end

            context "when the module is found" do
                before do
                    allow(http_client).to receive(:get).
                        with("http://puppetforge.example.com/api/v1/releases.json?module=puppetlabs/apache").
                        and_return('{"puppetlabs/apache":[{"version":"1.0.0","file":"/puppetlabs/apache.tgz","dependencies":[["puppetlabs/concat",">= 1.0.0"],["puppetlabs/stdlib","~> 2.0.0"]]},{"version":"2.0.0","dependencies":[]}]}')
                end

                it "returns a buffer containing the module archive" do
                    file_buffer = "file buffer"
                    expect(http_client).to receive(:download).
                        with("http://puppetforge.example.com/puppetlabs/apache.tgz").
                        and_return(file_buffer)

                    result = forge.get_module_buffer("puppetlabs", "apache", "1.0.0")
                    expect(result).to eq file_buffer
                end

                it "caches the download" do
                    file_buffer = "file buffer"
                    expect(http_client).to receive(:download).once.
                        with("http://puppetforge.example.com/puppetlabs/apache.tgz").
                        and_return(file_buffer)

                    forge.get_module_buffer("puppetlabs", "apache", "1.0.0")
                    forge.get_module_buffer("puppetlabs", "apache", "1.0.0")
                end
            end
        end

        describe "#get_module_metadata" do
            context "when the module doesn't exist" do
                it "raises an error" do
                    expect(http_client).to receive(:get).
                        with("http://puppetforge.example.com/puppetlabs/apache.json").
                        and_raise(OpenURI::HTTPError.new("404 Not Found", "Module not found"))

                    expect {
                        forge.get_module_metadata("puppetlabs", "apache")
                    }.to raise_error(ModuleNotFound)
                end
            end

            context "when versions of the module exist" do
                it "forwards the query directly" do
                    response = '{"puppetlabs/apache":[{"version":"1.0.0","dependencies":[["puppetlabs/concat",">= 1.0.0"],["puppetlabs/stdlib","~> 2.0.0"]]},{"version":"2.0.0","dependencies":[]}]}'
                    expect(http_client).to receive(:get).
                        with("http://puppetforge.example.com/puppetlabs/apache.json").
                        and_return(response)

                    metadata = forge.get_module_metadata("puppetlabs", "apache")
                    expect(metadata).to eq JSON.parse(response)
                end

                it "caches requests" do
                    expect(http_client).to receive(:get).once.
                        with("http://puppetforge.example.com/puppetlabs/apache.json").
                        and_return('{}')

                    forge.get_module_metadata("puppetlabs", "apache")
                    forge.get_module_metadata("puppetlabs", "apache")
                end
            end
        end

        describe "#get_module_metadata_with_dependencies" do
            context "the module isn't found" do
                it "raises an error" do
                    expect(http_client).to receive(:get).
                        with("http://puppetforge.example.com/api/v1/releases.json?module=nonexistant/nonexistant").
                        and_raise(OpenURI::HTTPError.new("410 Gone", "Module not found"))

                    expect {
                        forge.get_module_metadata_with_dependencies("nonexistant", "nonexistant", nil)
                    }.to raise_error ModuleNotFound
                end
            end

            context "when the module is found" do
                it "forwards the request directly" do
                    response = '{"puppetlabs/apache":[{"version":"1.0.0","dependencies":[["puppetlabs/concat",">= 1.0.0"],["puppetlabs/stdlib","~> 2.0.0"]]},{"version":"2.0.0","dependencies":[]}]}'
                    expect(http_client).to receive(:get).
                        with("http://puppetforge.example.com/api/v1/releases.json?module=puppetlabs/apache&version=1.0.0").
                        and_return(response)

                    result = forge.get_module_metadata_with_dependencies("puppetlabs", "apache", "1.0.0")

                    expect(result).to eq JSON.parse(response)
                end

                it "caches the result" do
                    response = '{"puppetlabs/apache":[{"version":"1.0.0","dependencies":[["puppetlabs/concat",">= 1.0.0"],["puppetlabs/stdlib","~> 2.0.0"]]},{"version":"2.0.0","dependencies":[]}]}'
                    expect(http_client).to receive(:get).once.
                        with("http://puppetforge.example.com/api/v1/releases.json?module=puppetlabs/apache&version=1.0.0").
                        and_return(response)

                    forge.get_module_metadata_with_dependencies("puppetlabs", "apache", "1.0.0")
                    forge.get_module_metadata_with_dependencies("puppetlabs", "apache", "1.0.0")
                end
            end
        end
    end
end
