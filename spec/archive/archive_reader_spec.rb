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

module PuppetLibrary::Archive
    describe ArchiveReader do
        let :reader do
            ArchiveReader.new(archive)
        end

        let :source_dir do
            Tempdir.new("zipping")
        end

        let :archive do
            archive = File.join(source_dir.path, "archive.tgz")
            write_tar_gzip!(archive) do |zip|
                zip.add_file("arrive.txt", 0644) { |entry| entry.write "say hello" }
                zip.add_file("later/depart.txt", 0644) { |entry| entry.write "say bye" }
            end
            archive
        end

        def write_tar_gzip!(file_name)
            tar = StringIO.new

            Gem::Package::TarWriter.new(tar) do |writer|
                yield(writer)
            end
            tar.seek(0)

            gz = Zlib::GzipWriter.new(File.new(file_name, 'wb'))
            gz.write(tar.read)
            tar.close
            gz.close
        end

        describe "#read_entry" do
            it "reads the first entry matched by the regex" do
                arrival_task = reader.read_entry /arrive/
                expect(arrival_task).to eq "say hello"
            end

            context "when the entry isn't found" do
                it "raises an error" do
                    expect {
                        reader.read_entry /xxx/
                    }.to raise_error /Couldn't find entry/
                end
            end
        end
    end
end
