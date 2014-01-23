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

module PuppetLibrary::ModuleRepo
    describe Multi do
        let(:subrepo_one) { double('subrepo_one').as_null_object }
        let(:subrepo_two) { double('subrepo_two').as_null_object }
        let(:multi_repo) do
            repo = Multi.new
            repo.add_repo(subrepo_one)
            repo.add_repo(subrepo_two)
            return repo
        end

        describe "#get_module_buffer" do
            context "when the module is found in a subrepository" do
                it "returns the module from the first subrepo it's found in" do
                    expect(subrepo_one).to receive(:get_module_buffer).with("puppetlabs", "apache", "1.0.0").and_return("puppetlabs/apache module: 1.0.0")
                    expect(subrepo_two).not_to receive(:get_mo_bufferdule_buffer)

                    mod = multi_repo.get_module_buffer("puppetlabs", "apache", "1.0.0")

                    expect(mod).to eq "puppetlabs/apache module: 1.0.0"
                end
            end

            context "when the module is not found in any subrepository" do
                it "raises an error" do
                    expect(subrepo_one).to receive(:get_module_buffer).with("puppetlabs", "nonexistant", "1.0.0").and_raise(PuppetLibrary::ModuleNotFound)
                    expect(subrepo_two).to receive(:get_module_buffer).with("puppetlabs", "nonexistant", "1.0.0").and_raise(PuppetLibrary::ModuleNotFound)

                    expect {
                        multi_repo.get_module_buffer("puppetlabs", "nonexistant", "1.0.0")
                    }.to raise_exception(PuppetLibrary::ModuleNotFound)
                end
            end
        end

        describe "#get_module_metadata" do
            context "when versions of the module are found in subrepositories" do
                it "combines the metadata" do
                    apache_module_metadata_one = {
                        "full_name" => "puppetlabs-apache", "releases" => [{"version"=>"1.0.0"}]
                    }
                    apache_module_metadata_two = {
                        "full_name" => "puppetlabs-apache", "releases" => [{"version"=>"2.0.0"}]
                    }
                    expect(subrepo_one).to receive(:get_module_metadata).with("puppetlabs", "apache").and_return(apache_module_metadata_one)
                    expect(subrepo_two).to receive(:get_module_metadata).with("puppetlabs", "apache").and_return(apache_module_metadata_two)

                    metadata_list = multi_repo.get_module_metadata("puppetlabs", "apache")

                    expect(metadata_list).to eq({
                        "full_name" => "puppetlabs-apache",
                        "releases" => [{"version"=>"1.0.0"}, {"version"=>"2.0.0"}]
                    })
                end
            end

            context "when no versions of the module are found in any subrepository" do
                it "raises an error" do
                    expect(subrepo_one).to receive(:get_module_metadata).with("puppetlabs", "apache").and_raise(PuppetLibrary::ModuleNotFound)
                    expect(subrepo_two).to receive(:get_module_metadata).with("puppetlabs", "apache").and_raise(PuppetLibrary::ModuleNotFound)

                    expect {
                        multi_repo.get_module_metadata("puppetlabs", "apache")
                    }.to raise_exception(PuppetLibrary::ModuleNotFound)
                end
            end

            context "when the same version of a module is found in multiple repositories" do
                it "returns the one from the first repository it appears in" do
                    apache_module_metadata_one = {
                        "full_name" => "puppetlabs-apache", "releases" => [{"version"=>"1.0.0", "repo" => "one"}]
                    }
                    apache_module_metadata_two = {
                        "full_name" => "puppetlabs-apache", "releases" => [{"version"=>"1.0.0", "repo" => "two"}]
                    }
                    expect(subrepo_one).to receive(:get_module_metadata).with("puppetlabs", "apache").and_return(apache_module_metadata_one)
                    expect(subrepo_two).to receive(:get_module_metadata).with("puppetlabs", "apache").and_return(apache_module_metadata_two)

                    metadata_list = multi_repo.get_module_metadata("puppetlabs", "apache")

                    expect(metadata_list).to eq({
                        "full_name" => "puppetlabs-apache",
                        "releases" => [{"version"=>"1.0.0", "repo"=>"one"}]
                    })
                end
            end
        end

        describe "#get_module_metadata_with_dependencies" do
            context "when no versions of the module are found in any subrepository" do
                it "raises an error" do
                    expect(subrepo_one).to receive(:get_module_metadata_with_dependencies).with("puppetlabs", "apache", nil).and_raise(PuppetLibrary::ModuleNotFound)
                    expect(subrepo_two).to receive(:get_module_metadata_with_dependencies).with("puppetlabs", "apache", nil).and_raise(PuppetLibrary::ModuleNotFound)

                    expect {
                        multi_repo.get_module_metadata_with_dependencies("puppetlabs", "apache", nil)
                    }.to raise_error(PuppetLibrary::ModuleNotFound)
                end
            end

            context "when versions of the module are found in subrepositories" do
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
                    expect(subrepo_one).to receive(:get_module_metadata_with_dependencies).with("puppetlabs", "apache", nil).and_return(apache_module_metadata_one)
                    expect(subrepo_two).to receive(:get_module_metadata_with_dependencies).with("puppetlabs", "apache", nil).and_return(apache_module_metadata_two)

                    metadata = multi_repo.get_module_metadata_with_dependencies("puppetlabs", "apache", nil)

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

            context "when the same version of a module is found in multiple repositories" do
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
                            "repo" => "1",
                            "dependencies" => [
                                [ "puppetlabs/concat", ">= 1.0.0" ],
                                [ "puppetlabs/stdlib", ">= 2.4.0" ]
                            ]
                        }
                    end
                    apache_module_metadata_two = base_metadata.deep_clone.tap do |meta|
                        meta["puppetlabs/apache"] << {
                            "version" => "1",
                            "repo" => "2",
                            "dependencies" => [
                                [ "puppetlabs/concat", ">= 1.0.0" ],
                                [ "puppetlabs/stdlib", ">= 2.4.0" ]
                            ]
                        }
                    end
                    expect(subrepo_one).to receive(:get_module_metadata_with_dependencies).with("puppetlabs", "apache", nil).and_return(apache_module_metadata_one)
                    expect(subrepo_two).to receive(:get_module_metadata_with_dependencies).with("puppetlabs", "apache", nil).and_return(apache_module_metadata_two)

                    metadata = multi_repo.get_module_metadata_with_dependencies("puppetlabs", "apache", nil)

                    expect(metadata["puppetlabs/apache"]).to eq [
                        {
                            "version"=>"1",
                            "repo"=>"1",
                            "dependencies"=> [["puppetlabs/concat", ">= 1.0.0"], ["puppetlabs/stdlib", ">= 2.4.0"]]
                        },
                    ]
                end
            end
        end
    end
end
