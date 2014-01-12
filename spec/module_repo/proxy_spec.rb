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

module PuppetLibrary::ModuleRepo
    describe Proxy do
        let(:http_client) { double('http_client') }
        let(:repo) { Proxy.new("http://puppetforge.example.com", http_client) }

        describe "#get_module" do
            context "when the module exists" do
                it "downloads the module" do
                    expect(http_client).to receive(:get).
                        with("http://puppetforge.example.com/api/v1/releases.json?module=puppetlabs/apache").
                        and_return('{"puppetlabs/apache":[{"file":"/system/releases/p/puppetlabs/puppetlabs-apache-1.2.3.tar.gz","version":"1.2.3","dependencies":[]}]}')
                    expect(http_client).to receive(:download).
                        with("http://puppetforge.example.com/system/releases/p/puppetlabs/puppetlabs-apache-1.2.3.tar.gz").
                        and_return("module buffer")

                    module_buffer = repo.get_module("puppetlabs", "apache", "1.2.3")
                    expect(module_buffer).to eq "module buffer"
                end
            end

            context "when the module doesn't exist" do
                it "returns nil" do
                    expect(http_client).to receive(:get).
                        with("http://puppetforge.example.com/api/v1/releases.json?module=puppetlabs/apache").
                        and_return('{"puppetlabs/apache":[{"file":"/system/releases/p/puppetlabs/puppetlabs-apache-1.2.3.tar.gz","version":"1.2.3","dependencies":[]}]}')

                    module_buffer = repo.get_module("puppetlabs", "apache", "9.9.9")
                    expect(module_buffer).to be_nil
                end
            end
        end

        describe "#get_metadata" do
            context "when the module doesn't exist" do
                it "returns an empty array" do
                    expect(http_client).to receive(:get).
                        with("http://puppetforge.example.com/api/v1/releases.json?module=puppetlabs/apache").
                        and_raise(OpenURI::HTTPError.new("404 Not Found", "Module not found"))

                    metadata = repo.get_metadata("puppetlabs", "apache")
                    expect(metadata).to be_empty
                end
            end

            context "when versions of the module exist" do
                it "returns an empty array" do
                    expect(http_client).to receive(:get).
                        with("http://puppetforge.example.com/api/v1/releases.json?module=puppetlabs/apache").
                        and_return('{"puppetlabs/apache":[{"version":"1.0.0","dependencies":[["puppetlabs/concat",">= 1.0.0"],["puppetlabs/stdlib","~> 2.0.0"]]},{"version":"2.0.0","dependencies":[]}]}')

                    metadata = repo.get_metadata("puppetlabs", "apache")
                    expect(metadata.size).to eq 2
                    expect(metadata.first).to eq({ "name" => "puppetlabs-apache", "author" => "puppetlabs", "version" => "1.0.0", "dependencies" => [{ "name" => "puppetlabs/concat", "version_requirement" => ">= 1.0.0" }, { "name" => "puppetlabs/stdlib", "version_requirement" => "~> 2.0.0" }] })
                    expect(metadata.last).to eq({ "name" => "puppetlabs-apache", "author" => "puppetlabs", "version" => "2.0.0", "dependencies" => [] })
                end
            end
        end
    end
end
