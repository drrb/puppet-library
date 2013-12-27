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

module PuppetLibrary
    class ModuleRepo
        def initialize(module_dir)
            @module_dir = module_dir
        end

        def get_metadata(author, module_name)
            Dir["#{@module_dir}/#{author}-#{module_name}*"].map do |module_path|
                tar = Gem::Package::TarReader.new(Zlib::GzipReader.open(module_path))
                tar.rewind
                metadata_source = tar.find {|e| e.full_name =~ /[^\/]+\/metadata\.json/}.read
                JSON.parse(metadata_source)
            end
        end
    end
end
