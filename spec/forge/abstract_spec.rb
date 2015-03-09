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
    describe Abstract do
        let(:forge) { Abstract.new(module_repo) }
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

        describe "#search_modules" do
            before do
                all_metadata = [{
                    "name"=>"puppetlabs-apache",
                    "version"=>"0.10.0",
                    "source"=>"git://github.com/puppetlabs/puppetlabs-apache.git",
                    "author"=>"puppetlabs",
                    "license"=>"Apache 2.0",
                    "summary"=>"Puppet module for Apache",
                    "description"=>"Module for Apache configuration",
                    "project_page"=>"https://github.com/puppetlabs/puppetlabs-apache"
                },{
                    "name"=>"dodgybrothers-ntp",
                    "version"=>"1.0.0",
                    "source"=>"git://github.com/dodgybrothers/puppet-ntp.git",
                    "author"=>"dodgybrothers",
                    "license"=>"Apache 2.0",
                    "summary"=>"Puppet module for NTP",
                    "description"=>"Module for NTP configuration",
                    "project_page"=>"https://github.com/dodgybrothers/puppet-ntp"
                }]
                allow(module_repo).to receive(:get_all_metadata).and_return(all_metadata)
                allow(module_repo).to receive(:get_md5).and_return("md5hexdigest")
            end

            it "matches by name" do
                search_results = forge.search_modules("apache")
                expect(search_results).to eq [{
                    "author"=>"puppetlabs",
                    "full_name"=>"puppetlabs-apache",
                    "name"=>"apache",
                    "summary"=>"Puppet module for Apache",
                    "project_page"=>"https://github.com/puppetlabs/puppetlabs-apache",
                    "releases"=>[{"version"=>"0.10.0"}],
                    "version"=>"0.10.0",
                    "tag_list"=>["puppetlabs", "apache"]
                }]
            end

            it "matches by author" do
                search_results = forge.search_modules("dodgybrothers")
                expect(search_results).to eq [{
                    "author"=>"dodgybrothers",
                    "full_name"=>"dodgybrothers-ntp",
                    "name"=>"ntp",
                    "summary"=>"Puppet module for NTP",
                    "project_page"=>"https://github.com/dodgybrothers/puppet-ntp",
                    "releases"=>[{"version"=>"1.0.0"}],
                    "version"=>"1.0.0",
                    "tag_list"=>["dodgybrothers", "ntp"]
                }]
            end

            context "when multiple versions of a module exist" do
                it "retuns merges the metadata, favoring the most recent one" do
                    all_metadata = [{
                        "name"=>"puppetlabs-apache",
                        "version"=>"0.10.0",
                        "source"=>"git://github.com/puppetlabs/puppetlabs-apache.git",
                        "author"=>"puppetlabs",
                        "license"=>"Apache 2.0",
                        "summary"=>"Puppet module for Apache",
                        "description"=>"Module for Apache configuration",
                        "project_page"=>"https://github.com/puppetlabs/puppetlabs-apache"
                    },{
                        "name"=>"puppetlabs-apache",
                        "version"=>"1.0.0",
                        "source"=>"git://github.com/puppetlabs/puppetlabs-apache-new.git",
                        "author"=>"puppetlabs",
                        "license"=>"GPL",
                        "summary"=>"New Puppet module for Apache",
                        "description"=>"New module for Apache configuration",
                        "project_page"=>"https://github.com/puppetlabs/puppetlabs-apache-new"
                    }]
                    expect(module_repo).to receive(:get_all_metadata).and_return(all_metadata)

                    search_results = forge.search_modules("apache")
                    expect(search_results).to eq [{
                        "author"=>"puppetlabs",
                        "full_name"=>"puppetlabs-apache",
                        "name"=>"apache",
                        "summary"=>"New Puppet module for Apache",
                        "project_page"=>"https://github.com/puppetlabs/puppetlabs-apache-new",
                        "releases"=>[{"version"=>"1.0.0"},{"version"=>"0.10.0"}],
                        "version"=>"1.0.0",
                        "tag_list"=>["puppetlabs", "apache"]
                    }]
                end
            end

            context "with no query" do
                it "retuns all metadata" do
                    search_results = forge.search_modules(nil)

                    search_results = search_results.sort_by {|r| r["name"]}
                    expect(search_results).to eq [{
                        "author"=>"puppetlabs",
                        "full_name"=>"puppetlabs-apache",
                        "name"=>"apache",
                        "summary"=>"Puppet module for Apache",
                        "project_page"=>"https://github.com/puppetlabs/puppetlabs-apache",
                        "releases"=>[{"version"=>"0.10.0"}],
                        "version"=>"0.10.0",
                        "tag_list"=>["puppetlabs", "apache"]
                    },{
                        "author"=>"dodgybrothers",
                        "full_name"=>"dodgybrothers-ntp",
                        "name"=>"ntp",
                        "summary"=>"Puppet module for NTP",
                        "project_page"=>"https://github.com/dodgybrothers/puppet-ntp",
                        "releases"=>[{"version"=>"1.0.0"}],
                        "version"=>"1.0.0",
                        "tag_list"=>["dodgybrothers", "ntp"]
                    }]
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
                        "summary" => "Apache module",
                        "version" => "1.1.0"
                    }, {
                        "author" => "puppetlabs",
                        "name" => "puppetlabs-apache",
                        "summary" => "Old Apache module",
                        "version" => "1.0.0"
                    } ]
                    expect(module_repo).to receive(:get_metadata).with("puppetlabs", "apache").and_return(metadata)
                    expect(module_repo).to receive(:get_md5).at_least(:once).and_return("md5hexdigest")

                    metadata = forge.get_module_metadata("puppetlabs", "apache")

                    expect(metadata["author"]).to eq "puppetlabs"
                    expect(metadata["full_name"]).to eq "puppetlabs-apache"
                    expect(metadata["name"]).to eq "apache"
                    expect(metadata["summary"]).to eq "Apache module"
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
                        "summary" => "Apache module",
                        "version" => "1.0.0",
                        "dependencies" => []
                    } ]
                    expect(module_repo).to receive(:get_metadata).with("puppetlabs", "apache").at_least(:once).and_return(metadata)
                    expect(module_repo).to receive(:get_md5).at_least(:once).and_return("md5hexdigest")

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
                        expect(module_repo).to receive(:get_md5).at_least(:once).and_return("md5hexdigest")

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
                        expect(module_repo).to receive(:get_md5).at_least(:once).and_return("md5hexdigest")

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
