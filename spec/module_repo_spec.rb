# Puppet Library
# Copyright (C) 2013 drrb
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
    describe ModuleRepo do
        include ModuleSpecHelper

        let(:module_dir) { "/tmp/#{$$}" }
        let(:module_repo) { ModuleRepo.new(module_dir) }

        before do
            FileUtils.mkdir_p module_dir
        end

        after do
            FileUtils.rm_rf module_dir
        end

        describe "#get_module" do
            context "when the module archive exists" do
                before do
                    add_module("puppetlabs", "apache", "1.0.0")
                end

                it "returns a the module archive as a file buffer" do
                    buffer = module_repo.get_module("puppetlabs", "apache", "1.0.0")

                    expect(buffer.path).to end_with("puppetlabs-apache-1.0.0.tar.gz")
                end
            end

            context "when the module file doesn't exist" do
                it "returns nil" do
                    buffer = module_repo.get_module("puppetlabs", "noneixstant", "1.0.0")

                    expect(buffer).to be_nil
                end
            end
        end

        describe "#get_metadata" do
            context "when the module directory is empty" do
                it "returns an empty array" do
                    metadata_list = module_repo.get_metadata("puppetlabs", "apache")
                    expect(metadata_list).to be_empty
                end
            end

            context "when the module directory contains the requested module" do
                before do
                    add_module("puppetlabs", "apache", "1.0.0")
                    add_module("puppetlabs", "apache", "1.1.0")
                end

                it "returns an array containing the module's versions' metadata" do
                    metadata_list = module_repo.get_metadata("puppetlabs", "apache")
                    expect(metadata_list.size).to eq 2
                    metadata_list = metadata_list.sort_by {|m| m["version"] }
                    expect(metadata_list[0]).to eq({ "name" => "puppetlabs-apache", "version" => "1.0.0" })
                    expect(metadata_list[1]).to eq({ "name" => "puppetlabs-apache", "version" => "1.1.0" })
                end
            end
        end
    end
end
