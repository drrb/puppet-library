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

module PuppetLibrary::Http
    module Cache
        class Disk
            def initialize(directory)
                @directory = directory
            end

            def get(path)
                unless include? path
                    buffer = yield
                    save(path, buffer)
                end
                retrieve(path)
            end

            private
            def include?(path)
                File.exist? entry_path(path)
            end

            def save(path, buffer)
                file_path = entry_path(path)
                FileUtils.mkdir_p File.dirname(file_path)
                File.open(file_path, "w") do |file|
                    file.write buffer.read
                end
            end

            def retrieve(path)
                File.open(entry_path(path))
            end

            def entry_path(path)
                File.join(@directory, path)
            end
        end
    end
end
