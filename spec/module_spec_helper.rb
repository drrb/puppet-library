# -*- encoding: utf-8 -*-
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

require 'zlib'
require 'rubygems/package'

module ModuleSpecHelper
    def write_tar_gzip(file_name)
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

    def add_module(author, name, version)
        full_name = "#{author}-#{name}"
        fqn = "#{full_name}-#{version}"
        module_file = File.join(module_dir, "#{fqn}.tar.gz")

        write_tar_gzip(module_file) do |archive|
            archive.add_file("#{fqn}/metadata.json", 0644) do |file|
                content = {
                    "name" => full_name,
                    "version" => version
                }
                file.write content.to_json
            end
        end
    end
end
