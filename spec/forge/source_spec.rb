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

class Tgz
    def initialize(buffer)
        @buffer = buffer
    end

    def read(entry_regex)
        @buffer.rewind
        tar = Gem::Package::TarReader.new(Zlib::GzipReader.wrap(@buffer))
        tar.rewind
        entry = tar.find {|e| e.full_name =~ entry_regex}
        raise "No entry matching #{entry_regex} found" if entry.nil?
        entry.read
    end
end

RSpec::Matchers.define :be_tgz_with do |expected_file_regex, expected_content_regex|
    match do |buffer|
        file_content = Tgz.new(buffer).read expected_file_regex
        file_content =~ expected_content_regex
    end
end

module PuppetLibrary::Forge
    describe Source do
        let(:module_dir) { Tempdir.create("module_dir") }
        let(:forge) { Source.new(module_dir) }

        before do
            set_module("puppetlabs", "apache", "1.0.0")
            add_module_dependency("puppetlabs", "stdlib", ">= 2.4.0")
            add_module_dependency("puppetlabs", "concat", ">= 1.0.1")
        end

        after do
            rm_rf module_dir
        end

        def set_module(author, name, version)
            File.open(File.join(module_dir, "Modulefile"), "w") do |modulefile|
                modulefile.puts <<-EOF
                name '#{author}-#{name}'
                version '#{version}'
                author '#{author}'
                description '#{author} #{name} module, version #{version}'
                EOF
            end
        end

        def add_module_dependency(author, name, spec)
            File.open(File.join(module_dir, "Modulefile"), "a") do |modulefile|
                modulefile.puts <<-EOF
                dependency "#{author}/#{name}", "#{spec}"
                EOF
            end
        end

        describe "#initialize" do
            context "when the module directory doesn't exist" do
                before do
                    rm_rf module_dir
                end

                it "raises an error" do
                    expect {
                        Source.new(module_dir)
                    }.to raise_error /Module directory .* doesn't exist/
                end
            end

            context "when the module directory isn't readable" do
                before do
                    chmod 0400, module_dir
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
                it "returns a buffer of the packaged module" do
                    buffer = forge.get_module("puppetlabs", "apache", "1.0.0")

                    expect(buffer).to be_tgz_with(/Modulefile/, /apache/)
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
                it "returns an empty list" do
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
