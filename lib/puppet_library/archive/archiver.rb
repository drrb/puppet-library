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
    # Adapted from https://gist.github.com/sinisterchipmunk/1335041
    module Archiver
        def self.archive_dir(dir, basedir)
            gzip(tar(dir, basedir))
        end

        private
        # gzips the underlying string in the given StringIO,
        # returning a new StringIO representing the
        # compressed file.
        def self.gzip(tar_buffer)
            zip_buffer = StringIO.new("")
            zipper = Zlib::GzipWriter.new(zip_buffer)
            zipper.write tar_buffer.string
            zipper.close # this is necessary!
            # z was closed to write the gzip footer, so
            # now we need a new StringIO
            StringIO.new zip_buffer.string
        end

        def self.tar(path, basedir)
            tarfile = StringIO.new("")
            Gem::Package::TarWriter.new(tarfile) do |tar|
                walk_directory(path) do |file|
                    entry_name = file.sub /^#{Regexp::escape path}\/?/, "#{basedir}/"
                    TarEntry.from(file).add_to!(tar, entry_name)
                end
            end
            tarfile.rewind
            tarfile
        end

        def self.walk_directory(basedir)
            Dir[File.join(basedir, "**/*")].each do |file|
                yield(file)
            end
        end

        class TarEntry
            def self.from(file)
                TarEntry.new(file)
            end

            def initialize(file)
                @file = file
            end

            def add_to!(tar, entry_name)
                mode = File.stat(@file).mode
                if File.directory?(@file)
                    tar.mkdir(entry_name, mode)
                else
                    tar.add_file(entry_name, mode) do |entry|
                        File.open(@file, "rb") { |file| entry.write file.read }
                    end
                end
            end
        end
    end
end
