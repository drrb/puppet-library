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

require 'fileutils'
require 'monitor'

module PuppetLibrary::Http
    module Cache
        class Disk
            def initialize(directory)
                @directory = directory
                @mutex = Monitor.new
            end

            def get(path = "entry")
                unless include? path
                    buffer = yield
                    save(path, buffer)
                end
                retrieve(path)
            end

            def clear
                @mutex.synchronize do
                    FileUtils.rm_rf @directory
                end
            end

            private
            def include?(path)
                @mutex.synchronize do
                    File.exist? entry_path(path)
                end
            end

            def save(path, buffer)
                @mutex.synchronize do
                    file_path = entry_path(path)
                    FileUtils.mkdir_p File.dirname(file_path)
                    File.open(file_path, "w") do |file|
                        file.write buffer.read
                    end
                end
            end

            def retrieve(path)
                @mutex.synchronize do
                    File.open(entry_path(path))
                end
            end

            def entry_path(path)
                @mutex.synchronize do
                    File.join(@directory, path)
                end
            end
        end
    end
end
