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

        describe "#get_metadata" do
            context "when versions of the module are found in subrepositories" do
                it "returns the metadata in an array" do
                    apache_module_metadata_one = { "name" => "apache", "version" => "1.0.0" }
                    apache_module_metadata_two = { "name" => "apache", "version" => "2.0.0" }
                    expect(subrepo_one).to receive(:get_metadata).with("puppetlabs", "apache").and_return([apache_module_metadata_one])
                    expect(subrepo_two).to receive(:get_metadata).with("puppetlabs", "apache").and_return([apache_module_metadata_two])

                    metadata_list = multi_repo.get_metadata("puppetlabs", "apache") 

                    expect(metadata_list).to eq [ apache_module_metadata_one, apache_module_metadata_two ]
                end
            end

            context "when no versions of the module are found in any subrepository" do
                it "returns an empty array" do
                    expect(subrepo_one).to receive(:get_metadata).with("puppetlabs", "apache").and_return([])
                    expect(subrepo_two).to receive(:get_metadata).with("puppetlabs", "apache").and_return([])

                    metadata_list = multi_repo.get_metadata("puppetlabs", "apache") 

                    expect(metadata_list).to be_empty
                end
            end

            context "when the same version of a module is found in multiple repositories" do
                it "returns the one from the first repository it appears in" do
                    apache_module_metadata_one = { "name" => "apache", "version" => "1.0.0", "repo" => "one" }
                    apache_module_metadata_two = { "name" => "apache", "version" => "1.0.0", "repo" => "two" }
                    expect(subrepo_one).to receive(:get_metadata).with("puppetlabs", "apache").and_return([apache_module_metadata_one])
                    expect(subrepo_two).to receive(:get_metadata).with("puppetlabs", "apache").and_return([apache_module_metadata_two])

                    metadata_list = multi_repo.get_metadata("puppetlabs", "apache") 

                    expect(metadata_list).to eq [ apache_module_metadata_one ]
                end
            end
        end
    end
end
