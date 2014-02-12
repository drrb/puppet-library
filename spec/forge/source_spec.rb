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

        describe "#get_module_buffer" do
            context "when the requested module doesn't match the source module" do
                it "returns nil" do
                    expect(forge.get_module_buffer("puppetlabs", "apache", "0.9.0")).to be_nil
                end
            end

            context "when the source module is requested" do
                it "returns a buffer of the packaged module" do
                    buffer = forge.get_module_buffer("puppetlabs", "apache", "1.0.0")

                    expect(buffer).to be_tgz_with(/Modulefile/, /apache/)
                end
            end
        end
    end
end
