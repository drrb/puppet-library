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

class Hash
    def deep_clone
        other = clone
        keys.each do |key|
            other[key] = self[key].clone
        end
        other
    end
end

module PuppetLibrary::Forge
    describe Multi do
        let(:subforge_one) { double('subforge_one').as_null_object }
        let(:subforge_two) { double('subforge_two').as_null_object }
        let(:multi_forge) do
            forge = Multi.new
            forge.add_forge(subforge_one)
            forge.add_forge(subforge_two)
            return forge
        end

        describe "#search_modules" do
            context "when no modules match in any subforge" do
                it "returns an empty array" do
                    expect(subforge_one).to receive(:search_modules).with("apache").and_return([])
                    expect(subforge_two).to receive(:search_modules).with("apache").and_return([])

                    result = multi_forge.search_modules("apache")

                    expect(result).to eq []
                end
            end

            context "when modules match in subforges" do
                it "returns an array with all of them" do
                    apache = { "author" => "puppetlabs", "full_name" => "puppetlabs/apache", "version" => "1"}
                    concat = { "author" => "puppetlabs", "full_name" => "puppetlabs/concat", "version" => "1"}
                    expect(subforge_one).to receive(:search_modules).with("puppetlabs").and_return([apache])
                    expect(subforge_two).to receive(:search_modules).with("puppetlabs").and_return([concat])

                    result = multi_forge.search_modules("puppetlabs")

                    expect(result).to eq [apache, concat]
                end
            end

            context "when modules match in subforges that overlap" do
                it "favours the details of the ones in the first repository" do
                    apache_1 = { "author" => "puppetlabs", "full_name" => "puppetlabs/apache", "desc" => "one", "version" => "1"}
                    apache_2 = { "author" => "puppetlabs", "full_name" => "puppetlabs/apache", "desc" => "two", "version" => "2"}
                    expect(subforge_one).to receive(:search_modules).with("puppetlabs").and_return([apache_1])
                    expect(subforge_two).to receive(:search_modules).with("puppetlabs").and_return([apache_2])

                    result = multi_forge.search_modules("puppetlabs")

                    expect(result.size).to eq 1
                    expect(result.first["desc"]).to eq "one"
                end

                it "sets the version to the maximum version" do
                    apache_1 = { "author" => "puppetlabs", "full_name" => "puppetlabs/apache", "desc" => "one", "version" => "1"}
                    apache_2 = { "author" => "puppetlabs", "full_name" => "puppetlabs/apache", "desc" => "two", "version" => "2"}
                    expect(subforge_one).to receive(:search_modules).with("puppetlabs").and_return([apache_1])
                    expect(subforge_two).to receive(:search_modules).with("puppetlabs").and_return([apache_2])

                    result = multi_forge.search_modules("puppetlabs")

                    expect(result.size).to eq 1
                    expect(result.first["version"]).to eq "2"
                end

                it "combines the available tags" do
                    apache_1 = { "author" => "puppetlabs", "full_name" => "puppetlabs/apache", "desc" => "one", "version" => "1", "tag_list" => ["a", "b"]}
                    apache_2 = { "author" => "puppetlabs", "full_name" => "puppetlabs/apache", "desc" => "two", "version" => "2", "tag_list" => ["a", "c"]}
                    expect(subforge_one).to receive(:search_modules).with("puppetlabs").and_return([apache_1])
                    expect(subforge_two).to receive(:search_modules).with("puppetlabs").and_return([apache_2])

                    result = multi_forge.search_modules("puppetlabs")

                    tags = result.first["tag_list"]
                    expect(tags).to eq ["a", "b", "c"]
                end

                it "combines the available versions, in order" do
                    apache_3 = { "author" => "puppetlabs", "full_name" => "puppetlabs/apache", "desc" => "two", "version" => "3", "releases" => [{"version" => "3"}]}
                    apache_1 = { "author" => "puppetlabs", "full_name" => "puppetlabs/apache", "desc" => "one", "version" => "1", "releases" => [{"version" => "1"}]}
                    apache_2 = { "author" => "puppetlabs", "full_name" => "puppetlabs/apache", "desc" => "two", "version" => "2", "releases" => [{"version" => "2"}]}
                    expect(subforge_one).to receive(:search_modules).with("puppetlabs").and_return([apache_1, apache_3])
                    expect(subforge_two).to receive(:search_modules).with("puppetlabs").and_return([apache_2])

                    result = multi_forge.search_modules("puppetlabs")

                    tags = result.first["releases"]
                    expect(tags).to eq [ {"version" => "3"}, {"version" => "2"}, {"version" => "1"} ]
                end
            end
        end

        describe "#get_module_buffer" do
            context "when the module is found in a subforge" do
                it "returns the module from the first subforge it's found in" do
                    expect(subforge_one).to receive(:get_module_buffer).with("puppetlabs", "apache", "1.0.0").and_return("puppetlabs/apache module: 1.0.0")
                    expect(subforge_two).not_to receive(:get_mo_bufferdule_buffer)

                    mod = multi_forge.get_module_buffer("puppetlabs", "apache", "1.0.0")

                    expect(mod).to eq "puppetlabs/apache module: 1.0.0"
                end
            end

            context "when the module is not found in any subforge" do
                it "raises an error" do
                    expect(subforge_one).to receive(:get_module_buffer).with("puppetlabs", "nonexistant", "1.0.0").and_raise(ModuleNotFound)
                    expect(subforge_two).to receive(:get_module_buffer).with("puppetlabs", "nonexistant", "1.0.0").and_raise(ModuleNotFound)

                    expect {
                        multi_forge.get_module_buffer("puppetlabs", "nonexistant", "1.0.0")
                    }.to raise_exception(ModuleNotFound)
                end
            end
        end

        describe "#get_module_metadata" do
            context "when versions of the module are found in subforges" do
                it "combines the metadata" do
                    apache_module_metadata_one = {
                        "full_name" => "puppetlabs-apache", "releases" => [{"version"=>"1.0.0"}]
                    }
                    apache_module_metadata_two = {
                        "full_name" => "puppetlabs-apache", "releases" => [{"version"=>"2.0.0"}]
                    }
                    expect(subforge_one).to receive(:get_module_metadata).with("puppetlabs", "apache").and_return(apache_module_metadata_one)
                    expect(subforge_two).to receive(:get_module_metadata).with("puppetlabs", "apache").and_return(apache_module_metadata_two)

                    metadata_list = multi_forge.get_module_metadata("puppetlabs", "apache")

                    expect(metadata_list).to eq({
                        "full_name" => "puppetlabs-apache",
                        "releases" => [{"version"=>"1.0.0"}, {"version"=>"2.0.0"}]
                    })
                end
            end

            context "when no versions of the module are found in any subforge" do
                it "raises an error" do
                    expect(subforge_one).to receive(:get_module_metadata).with("puppetlabs", "apache").and_raise(ModuleNotFound)
                    expect(subforge_two).to receive(:get_module_metadata).with("puppetlabs", "apache").and_raise(ModuleNotFound)

                    expect {
                        multi_forge.get_module_metadata("puppetlabs", "apache")
                    }.to raise_exception(ModuleNotFound)
                end
            end

            context "when the same version of a module is found in multiple forges" do
                it "returns the one from the first forge it appears in" do
                    apache_module_metadata_one = {
                        "full_name" => "puppetlabs-apache", "releases" => [{"version"=>"1.0.0", "forge" => "one"}]
                    }
                    apache_module_metadata_two = {
                        "full_name" => "puppetlabs-apache", "releases" => [{"version"=>"1.0.0", "forge" => "two"}]
                    }
                    expect(subforge_one).to receive(:get_module_metadata).with("puppetlabs", "apache").and_return(apache_module_metadata_one)
                    expect(subforge_two).to receive(:get_module_metadata).with("puppetlabs", "apache").and_return(apache_module_metadata_two)

                    metadata_list = multi_forge.get_module_metadata("puppetlabs", "apache")

                    expect(metadata_list).to eq({
                        "full_name" => "puppetlabs-apache",
                        "releases" => [{"version"=>"1.0.0", "forge"=>"one"}]
                    })
                end
            end
        end

        describe "#get_module_metadata_with_dependencies" do
            context "when no versions of the module are found in any subforge" do
                it "raises an error" do
                    expect(subforge_one).to receive(:get_module_metadata_with_dependencies).with("puppetlabs", "apache", nil).and_raise(ModuleNotFound)
                    expect(subforge_two).to receive(:get_module_metadata_with_dependencies).with("puppetlabs", "apache", nil).and_raise(ModuleNotFound)

                    expect {
                        multi_forge.get_module_metadata_with_dependencies("puppetlabs", "apache", nil)
                    }.to raise_error(ModuleNotFound)
                end
            end

            context "when versions of the module are found in subforges" do
                it "a merged hash of the metadata" do
                    base_metadata = {
                        "puppetlabs/apache" => [ ],
                        "puppetlabs/stdlib" => [
                            {
                                "version" => "2.4.0",
                                "dependencies" => [ ]
                            }
                        ],
                        "puppetlabs/concat" => [
                            {
                                "version" => "1.0.0",
                                "dependencies" => [ ]
                            }
                        ]
                    }
                    apache_module_metadata_one = base_metadata.deep_clone.tap do |meta|
                        meta["puppetlabs/apache"] << {
                            "version" => "1",
                            "dependencies" => [
                                [ "puppetlabs/concat", ">= 1.0.0" ],
                                [ "puppetlabs/stdlib", ">= 2.4.0" ]
                            ]
                        }
                    end
                    apache_module_metadata_two = base_metadata.deep_clone.tap do |meta|
                        meta["puppetlabs/apache"] << {
                            "version" => "2",
                            "dependencies" => [
                                [ "puppetlabs/concat", ">= 1.0.0" ],
                                [ "puppetlabs/stdlib", ">= 2.4.0" ]
                            ]
                        }
                    end
                    expect(subforge_one).to receive(:get_module_metadata_with_dependencies).with("puppetlabs", "apache", nil).and_return(apache_module_metadata_one)
                    expect(subforge_two).to receive(:get_module_metadata_with_dependencies).with("puppetlabs", "apache", nil).and_return(apache_module_metadata_two)

                    metadata = multi_forge.get_module_metadata_with_dependencies("puppetlabs", "apache", nil)

                    expect(metadata["puppetlabs/apache"]).to eq [
                        {
                            "version"=>"1",
                            "dependencies"=> [["puppetlabs/concat", ">= 1.0.0"], ["puppetlabs/stdlib", ">= 2.4.0"]]
                        },
                        {
                            "version"=>"2",
                            "dependencies"=> [["puppetlabs/concat", ">= 1.0.0"], ["puppetlabs/stdlib", ">= 2.4.0"]]
                        }
                    ]
                end
            end

            context "when the same version of a module is found in multiple forges" do
                it "favours the one it finds first" do
                    base_metadata = {
                        "puppetlabs/apache" => [ ],
                        "puppetlabs/stdlib" => [
                            {
                                "version" => "2.4.0",
                                "dependencies" => [ ]
                            }
                        ],
                        "puppetlabs/concat" => [
                            {
                                "version" => "1.0.0",
                                "dependencies" => [ ]
                            }
                        ]
                    }
                    apache_module_metadata_one = base_metadata.deep_clone.tap do |meta|
                        meta["puppetlabs/apache"] << {
                            "version" => "1",
                            "forge" => "1",
                            "dependencies" => [
                                [ "puppetlabs/concat", ">= 1.0.0" ],
                                [ "puppetlabs/stdlib", ">= 2.4.0" ]
                            ]
                        }
                    end
                    apache_module_metadata_two = base_metadata.deep_clone.tap do |meta|
                        meta["puppetlabs/apache"] << {
                            "version" => "1",
                            "forge" => "2",
                            "dependencies" => [
                                [ "puppetlabs/concat", ">= 1.0.0" ],
                                [ "puppetlabs/stdlib", ">= 2.4.0" ]
                            ]
                        }
                    end
                    expect(subforge_one).to receive(:get_module_metadata_with_dependencies).with("puppetlabs", "apache", nil).and_return(apache_module_metadata_one)
                    expect(subforge_two).to receive(:get_module_metadata_with_dependencies).with("puppetlabs", "apache", nil).and_return(apache_module_metadata_two)

                    metadata = multi_forge.get_module_metadata_with_dependencies("puppetlabs", "apache", nil)

                    expect(metadata["puppetlabs/apache"]).to eq [
                        {
                            "version"=>"1",
                            "forge"=>"1",
                            "dependencies"=> [["puppetlabs/concat", ">= 1.0.0"], ["puppetlabs/stdlib", ">= 2.4.0"]]
                        },
                    ]
                end
            end
        end
    end
end
