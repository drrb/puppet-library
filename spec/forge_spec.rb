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

module PuppetLibrary
    describe Forge do
        let(:forge) { Forge.new(module_repo) }
        let(:module_repo) { double('module_repo') }

        describe "#get_module_buffer" do
            context "module version not found" do
                it "raises an error" do
                    expect(module_repo).to receive(:get_module).with("puppetlabs", "apache", "1.0.0").and_return(nil)

                    expect {
                        forge.get_module_buffer("puppetlabs", "apache", "1.0.0")
                    }.to raise_error ModuleNotFound
                end
            end

            context "when the module is found" do
                it "returns a buffer containing the module archive" do
                    file_buffer = "module content"
                    expect(module_repo).to receive(:get_module).with("puppetlabs", "apache", "1.0.0").and_return(file_buffer)

                    result = forge.get_module_buffer("puppetlabs", "apache", "1.0.0")
                    expect(result).to eq file_buffer
                end
            end
        end

        describe "#get_module_metadata" do
            context "when no modules found" do
                it "raises an error" do
                    expect(module_repo).to receive(:get_metadata).with("nonexistant", "nonexistant").and_return([])

                    expect {
                        forge.get_module_metadata("nonexistant", "nonexistant")
                    }.to raise_error ModuleNotFound
                end
            end

            context "when module versions found" do
                it "returns metadata for all versions" do
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

                    metadata = forge.get_module_metadata("puppetlabs", "apache")

                    expect(metadata["author"]).to eq "puppetlabs"
                    expect(metadata["full_name"]).to eq "puppetlabs/apache"
                    expect(metadata["name"]).to eq "apache"
                    expect(metadata["desc"]).to eq "Apache module"
                    expect(metadata["releases"]).to eq [
                        {"version" => "1.0.0"},
                        {"version" => "1.1.0"}
                    ]
                end
            end
        end

        describe "#get_module_metadata_with_dependencies" do
            context "when no module versions found" do
                it "raises an error" do
                    expect(module_repo).to receive(:get_metadata).with("nonexistant", "nonexistant").and_return([])

                    expect {
                        forge.get_module_metadata_with_dependencies("nonexistant", "nonexistant", "1.0.0")
                    }.to raise_error ModuleNotFound
                end
            end

            context "when only different module versions found" do
                it "returns an empty array" do
                    metadata = [ {
                        "author" => "puppetlabs",
                        "name" => "puppetlabs-apache",
                        "description" => "Apache module",
                        "version" => "1.0.0",
                        "dependencies" => []
                    } ]
                    expect(module_repo).to receive(:get_metadata).with("puppetlabs", "apache").at_least(:once).and_return(metadata)

                    result = forge.get_module_metadata_with_dependencies("puppetlabs", "apache", "2.0.0")
                    expect(result).to eq({"puppetlabs/apache" => []})
                end
            end

            context "when module versions found" do
                context "when a version specified" do
                    it "returns metadata for that module version and its dependencies" do
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
                                { "name" => "puppetlabs/newthing", "version_requirement" => ">= 1.0.0" }
                            ]
                        } ]
                        stdlib_metadata = [ {
                            "author" => "puppetlabs",
                            "name" => "puppetlabs-stdlib",
                            "description" => "Stdlib module",
                            "version" => "2.4.0",
                            "dependencies" => [ ]
                        } ]
                        concat_metadata = [ {
                            "author" => "puppetlabs",
                            "name" => "puppetlabs-concat",
                            "description" => "Concat module",
                            "version" => "1.0.0",
                            "dependencies" => [ ]
                        } ]
                        newthing_metadata = [ {
                            "author" => "puppetlabs",
                            "name" => "puppetlabs-newthing",
                            "description" => "New module",
                            "version" => "1.0.0",
                            "dependencies" => [ ]
                        } ]
                        expect(module_repo).to receive(:get_metadata).with("puppetlabs", "apache").at_least(:once).and_return(apache_metadata)
                        expect(module_repo).to receive(:get_metadata).with("puppetlabs", "stdlib").and_return(stdlib_metadata)
                        expect(module_repo).to receive(:get_metadata).with("puppetlabs", "concat").and_return(concat_metadata)
                        expect(module_repo).to receive(:get_metadata).with("puppetlabs", "newthing").and_return(newthing_metadata)

                        result = forge.get_module_metadata_with_dependencies("puppetlabs", "apache", "1.0.0")
                        expect(result.keys.sort).to eq(["puppetlabs/apache", "puppetlabs/concat", "puppetlabs/stdlib"])
                        expect(result["puppetlabs/apache"].size).to eq(1)
                        expect(result["puppetlabs/apache"][0]["file"]).to eq("/modules/puppetlabs-apache-1.0.0.tar.gz")
                        expect(result["puppetlabs/apache"][0]["version"]).to eq("1.0.0")
                        expect(result["puppetlabs/apache"][0]["version"]).to eq("1.0.0")
                    end
                end
                context "when no version specified" do
                    it "returns metadata for all module versions and their dependencies" do
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
                        expect(module_repo).to receive(:get_metadata).with("puppetlabs", "apache").at_least(:once).and_return(apache_metadata)
                        expect(module_repo).to receive(:get_metadata).with("puppetlabs", "stdlib").and_return(stdlib_metadata)
                        expect(module_repo).to receive(:get_metadata).with("puppetlabs", "concat").and_return(concat_metadata)

                        result = forge.get_module_metadata_with_dependencies("puppetlabs", "apache", nil)
                        expect(result.keys.sort).to eq(["puppetlabs/apache", "puppetlabs/concat", "puppetlabs/stdlib"])
                        expect(result["puppetlabs/apache"].size).to eq(2)
                        expect(result["puppetlabs/apache"][0]["file"]).to eq("/modules/puppetlabs-apache-1.0.0.tar.gz")
                        expect(result["puppetlabs/apache"][0]["version"]).to eq("1.0.0")
                        expect(result["puppetlabs/apache"][0]["version"]).to eq("1.0.0")
                    end
                end
            end
        end
    end
end
