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

module PuppetLibrary::Forge
    class Source
        def initialize(module_dir)
            raise "Module directory '#{module_dir}' doesn't exist" unless File.directory? module_dir
            raise "Module directory '#{module_dir}' isn't readable" unless File.executable? module_dir
            @module_dir = module_dir
        end

        def get_module_buffer(author, name, version)
            module_file = File.join(@module_dir, "Modulefile")
            return nil unless File.read(module_file).include? version
            Archiver.new.archive(@module_dir, "#{author}-#{name}-#{version}")
        end
    end
end

require 'rubygems/package'
require 'zlib'

# Adapted from https://gist.github.com/sinisterchipmunk/1335041
class Archiver
    def archive(dir, basedir)
        gzip(tar(dir, basedir))
    end

    def tar(path, basedir)
        tarfile = StringIO.new("")
        Gem::Package::TarWriter.new(tarfile) do |tar|
            Dir[File.join(path, "**/*")].each do |file|
                mode = File.stat(file).mode
                relative_file = file.sub /^#{Regexp::escape path}\/?/, "#{basedir}/"
                if File.directory?(file)
                    tar.mkdir relative_file, mode
                else
                    tar.add_file relative_file, mode do |tf|
                        File.open(file, "rb") { |f| tf.write f.read }
                    end
                end
            end
        end
        tarfile.rewind
        tarfile
    end

    # gzips the underlying string in the given StringIO,
    # returning a new StringIO representing the
    # compressed file.
    def gzip(tarfile)
        gz = StringIO.new("")
        z = Zlib::GzipWriter.new(gz)
        z.write tarfile.string
        z.close # this is necessary!
        # z was closed to write the gzip footer, so
        # now we need a new StringIO
        StringIO.new gz.string
    end
end

