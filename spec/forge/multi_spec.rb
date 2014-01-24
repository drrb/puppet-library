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
