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

module PuppetLibrary::PuppetModule
    describe Modulefile do
        let(:module_file) { Tempfile.new("Modulefile") }

        def write_modulefile(content)
            File.open(module_file.path, "w") do |f|
                f.write content
            end
        end

        before do
            write_modulefile <<-EOF
                name 'joe-ficticious'
                version '1.2.3'
                source 'git://example.com/joe/puppet-ficticious.git'
                author 'joe'
                license 'Apache 2.0'
                summary 'Example module'
                description 'Module for use in a test'
                project_page 'https://example.com/joe/puppet-apache'

                dependency 'example/standard', '>= 2.3.4'
                dependency 'example/other', '>= 5.6.7'
            EOF
        end

        describe "#read" do
            let(:metadata) { Modulefile.read(module_file.path) }

            it "parses the name" do
                expect(metadata.get_name).to eq "joe-ficticious"
            end

            it "parses the version" do
                expect(metadata.get_version).to eq "1.2.3"
            end

            it "parses the author" do
                expect(metadata.get_author).to eq "joe"
            end

            it "parses the source URL" do
                expect(metadata.get_source).to eq "git://example.com/joe/puppet-ficticious.git"
            end

            it "parses the summary" do
                expect(metadata.get_summary).to eq "Example module"
            end

            it "parses the description" do
                expect(metadata.get_description).to eq "Module for use in a test"
            end

            it "parses the project URL" do
                expect(metadata.get_project_page).to eq "https://example.com/joe/puppet-apache"
            end

            it "parses the license name" do
                expect(metadata.get_license).to eq "Apache 2.0"
            end

            it "parses the dependencies" do
                expect(metadata.get_dependencies).to eq [
                    { "name" => "example/standard", "version_requirement" => '>= 2.3.4' },
                    { "name" => "example/other", "version_requirement" => '>= 5.6.7' }
                ]
            end

            context "when a bad value is configured" do
                it "logs the bad config, but doesn't blow up" do
                    write_modulefile <<-EOF
                        name 'joe-ficticious'
                        version '1.2.3'
                        rating '10'
                    EOF
                    expect(Modulefile).to receive(:log).with(/rating/)
                    Modulefile.read(module_file.path)
                end
            end
        end

        describe "#parse" do
            it "works like #read, but with a string" do
                metadata = Modulefile.parse("version '1.0.0'")
                expect(metadata.get_version).to eq "1.0.0"
            end

            context "when a a value is missing" do
                it "defaults to an empty string" do
                    modulefile = Modulefile.parse <<-EOF
                        name 'joe-ficticious'
                        version '1.2.3'
                    EOF
                    expect(modulefile.get_description).to eq ""
                end
            end
        end

        describe "#to_metadata" do
            let :modulefile do
                Modulefile.parse <<-EOF
                    name 'joe-ficticious'
                    version '1.2.3'
                    source 'git://example.com/joe/puppet-ficticious.git'
                    author 'joe'
                    license 'Apache 2.0'
                    summary 'Example module'
                    description 'Module for use in a test'
                    project_page 'https://example.com/joe/puppet-apache'

                    dependency 'example/standard', '>= 2.3.4'
                    dependency 'example/other', '>= 5.6.7'
                EOF
            end

            it "converts the modulefile into a metadata hash" do
                metadata = modulefile.to_metadata
                expect(metadata["name"]).to eq "joe-ficticious"
                expect(metadata["version"]).to eq "1.2.3"
                expect(metadata["source"]).to eq "git://example.com/joe/puppet-ficticious.git"
                expect(metadata["author"]).to eq "joe"
                expect(metadata["license"]).to eq "Apache 2.0"
                expect(metadata["summary"]).to eq "Example module"
                expect(metadata["description"]).to eq "Module for use in a test"
                expect(metadata["project_page"]).to eq "https://example.com/joe/puppet-apache"
                expect(metadata["dependencies"]).to eq [
                    { "name" => 'example/standard', "version_requirement" => ">= 2.3.4" },
                    { "name" => 'example/other', "version_requirement" => ">= 5.6.7" }
                ]
            end
        end
    end
end

