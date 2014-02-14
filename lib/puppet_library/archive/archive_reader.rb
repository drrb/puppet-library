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

require 'rubygems/package'
require 'zlib'

module PuppetLibrary::Archive
    class ArchiveReader
        def initialize(path)
            @path = path
        end

        def read_entry(entry_name_regex)
            tar = Gem::Package::TarReader.new(Zlib::GzipReader.open(@path))
            tar.rewind
            entry = tar.find {|e| e.full_name =~ entry_name_regex } or raise "Couldn't find entry in archive"
            entry.read
        end
    end
end
