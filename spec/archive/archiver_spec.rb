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
    describe Archiver do
        describe "#archive_dir" do
            let(:dir) { Tempdir.create("tozip") }

            def write_file!(filename, content)
                path = File.join(dir, filename)
                FileUtils.mkdir_p(File.dirname(path))
                File.open(path, "w") do |file|
                    file.write content
                end
            end

            it "tars and gzips a directory and its contents" do
                write_file! "arrive.txt", "say hello"
                write_file! "later/depart.txt", "say bye"

                buffer = Archiver.archive_dir(dir, "todo")

                expect(buffer).to be_tgz_with "todo/arrive.txt", "say hello"
                expect(buffer).to be_tgz_with "todo/later/depart.txt", "say bye"
            end
        end
    end
end

