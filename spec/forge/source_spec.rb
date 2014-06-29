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
    describe Source do
        let(:module_dir) { Tempdir.new("module_dir") }
        let(:metadata_file_path) { File.join(module_dir.path, "metadata.json") }
        let(:modulefile_path) { File.join(module_dir.path, "Modulefile") }
        let(:forge) { Source.new(module_dir) }

        before do
            File.open(metadata_file_path, "w") do |metadata_file|
                metadata = {
                  "name" => "puppetlabs-apache",
                  "version" => "1.0.0",
                  "author" => "puppetlabs",
                  "description" => "puppetlabs apache module, version 1.0.0",
                  "license" => "Apache 2.0",
                  "source" => "http://github.com/puppetlabs/puppetlabs-apache.git",
                  "project_page" => "https://github.com/puppetlabs/puppetlabs-apache",
                  "issues_url" => "https://github.com/puppetlabs/puppetlabs-apache/issues",
                  "dependencies" => [
                    { "name" => "puppetlabs/stdlib", "version_requirement" => ">= 2.4.0" },
                    { "name" => "puppetlabs/concat", "version_requirement" => ">= 1.0.1" }
                  ]
                }
                metadata_file.puts metadata.to_json
            end
        end

        describe "#configure" do
            it "exposes a configuration API" do
                forge = Source.configure do
                    path module_dir.path
                end
                expect(forge.instance_eval "@module_dir.path").to eq module_dir.path
            end
        end

        describe "#initialize" do
            context "when the module directory doesn't exist" do
                before do
                    rm_rf module_dir.path
                end

                it "raises an error" do
                    expect {
                        Source.new(module_dir)
                    }.to raise_error /Module directory .* doesn't exist/
                end
            end

            context "when the module directory isn't readable" do
                before do
                    chmod 0400, module_dir.path
                end

                after do
                    chmod 0777, module_dir.path
                end

                it "raises an error" do
                    expect {
                        Source.new(module_dir)
                    }.to raise_error /Module directory .* isn't readable/
                end
            end
        end

        describe "#get_module" do
            context "when the requested module doesn't match the source module" do
                it "returns nil" do
                    expect(forge.get_module("puppetlabs", "apache", "0.9.0")).to be_nil
                    expect(forge.get_module("puppetlabs", "stdlib", "1.0.0")).to be_nil
                end
            end

            context "when the source module is requested" do
                context "when there is a metadata file" do
                    it "includes the metadata file in the packaged application" do
                        buffer = forge.get_module("puppetlabs", "apache", "1.0.0")

                        expect(buffer).to be_tgz_with(/metadata.json/, /"name":"puppetlabs-apache"/)
                    end
                end

                context "when there is a modulefile with no metadata file" do
                    before do
                        FileUtils.rm metadata_file_path
                        File.open(modulefile_path, "w") do |modulefile|
                            modulefile.puts <<-EOF
                            name 'puppetlabs-apache'
                            version '2.0.0'
                            author 'puppetlabs'
                            description 'puppetlabs apache module, version 2.0.0'

                            dependency "puppetlabs/stdlib", ">= 2.4.0"
                            dependency "puppetlabs/concat", ">= 1.0.1"
                            EOF
                        end
                    end

                    it "returns a buffer of the packaged module" do
                        buffer = forge.get_module("puppetlabs", "apache", "2.0.0")

                        expect(buffer).to be_tgz_with(/Modulefile/, /puppetlabs-apache/)
                    end

                    it "generates a metadata file in the packaged application" do
                        buffer = forge.get_module("puppetlabs", "apache", "2.0.0")

                        expect(buffer).to be_tgz_with(/metadata.json/, /"name":"puppetlabs-apache"/)
                    end
                end
            end
        end

        describe "#get_metadata" do
            context "when the requested module doesn't match the source module" do
                it "returns an empty list" do
                    expect(forge.get_metadata("puppetlabs", "somethingelse")).to be_empty
                end
            end

            context "when the requested module is the source module" do
                it "returns the module's metadata" do
                    metadata = forge.get_metadata("puppetlabs", "apache").first

                    expect(metadata["name"]).to eq "puppetlabs-apache"
                    expect(metadata["version"]).to eq "1.0.0"
                    expect(metadata["author"]).to eq "puppetlabs"
                    expect(metadata["description"]).to eq "puppetlabs apache module, version 1.0.0"
                    expect(metadata["dependencies"]).to eq [
                        { "name" => "puppetlabs/stdlib", "version_requirement" => ">= 2.4.0" },
                        { "name" => "puppetlabs/concat", "version_requirement" => ">= 1.0.1" }
                    ]
                end
            end
        end

        describe "#get_all_metadata" do
            it "calls #get_metadata with the appropriate author and name" do
                expect(forge).to receive(:get_metadata).with("puppetlabs", "apache").and_return("metadata")
                expect(forge.get_all_metadata).to eq "metadata"
            end
        end
    end
end
