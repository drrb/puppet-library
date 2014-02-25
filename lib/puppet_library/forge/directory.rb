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

require 'json'
require 'puppet_library/forge/abstract'
require 'puppet_library/archive/archive_reader'

module PuppetLibrary::Forge

    # A forge that serves modules from a directory on disk.
    #
    # <b>Note:</b>
    # * The modules must be packaged in +.tar.gz+ format
    # * The modules must be named in the format <tt>author-modulename-version.tar.gz</tt>
    # * The modules must contain a +metadata.json+ file
    # That is, the format must be the same as what is produced by <tt>puppet module build</tt>
    #
    # <b>Usage:</b>
    #
    #    forge = PuppetLibrary::Forge::Directory.configure do |repo|
    #        # The path to serve the modules from
    #        repo.path = "/var/modules/cache
    #    end
    class Directory < PuppetLibrary::Forge::Abstract
        class Config
            attr_accessor :path
        end

        def self.configure
            config = Config.new
            yield(config)
            Directory.new(config.path)
        end

        # * <tt>:module_dir</tt> - The directory containing the packaged modules.
        def initialize(module_dir)
            super(self)
            raise "Module directory '#{module_dir}' doesn't exist" unless File.directory? module_dir
            raise "Module directory '#{module_dir}' isn't readable" unless File.executable? module_dir
            @module_dir = module_dir
        end

        def get_module(author, name, version)
            file_name = "#{author}-#{name}-#{version}.tar.gz"
            path = File.join(File.expand_path(@module_dir), file_name)
            if File.exist? path
                File.open(path, 'r')
            else
                nil
            end
        end

        def get_metadata(author = "*", module_name = "")
            Dir["#{@module_dir}/#{author}-#{module_name}*"].map do |module_path|
                archive = PuppetLibrary::Archive::ArchiveReader.new(module_path)
                metadata_file = archive.read_entry %r[[^/]+/metadata\.json$]
                JSON.parse(metadata_file)
            end
        end

        def get_all_metadata
            get_metadata
        end
    end
end
