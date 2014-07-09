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
require 'redcarpet'
require 'puppet_library/forge/abstract'
require 'puppet_library/archive/archive_reader'
require 'puppet_library/util/config_api'

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
    #    forge = PuppetLibrary::Forge::Directory.configure do
    #        # The path to serve the modules from
    #        path "/var/modules/cache"
    #    end
    class Directory < PuppetLibrary::Forge::Abstract

        def self.configure(&block)
            config_api = PuppetLibrary::Util::ConfigApi.for(Directory) do
                required :path, "path to a directory to serve modules from" do |dir|
                    Dir.new(File.expand_path(dir)).tap do |dir|
                        raise "Module directory '#{dir}' isn't readable" unless File.executable? dir
                    end
                end
            end
            config = config_api.configure(&block)
            Directory.new(config.get_path)
        end

        # * <tt>:module_dir</tt> - The directory containing the packaged modules.
        def initialize(module_dir)
            super(self)
            @module_dir = module_dir
        end

        def get_module(author, name, version)
            file_name = "#{author}-#{name}-#{version}.tar.gz"
            path = File.join(File.expand_path(@module_dir.path), file_name)
            if File.exist? path
                File.open(path, 'r')
            else
                nil
            end
        end

        def get_all_metadata
            get_metadata("*", "*")
        end

        def get_metadata(author, module_name)
            archives = Dir["#{@module_dir.path}/**/#{author}-#{module_name}-*.tar.gz"]
            archives.map {|path| read_metadata(path) }.compact
        end

        private
        def read_metadata(archive_path)
            archive = PuppetLibrary::Archive::ArchiveReader.new(archive_path)
            metadata_file = archive.read_entry %r[[^/]+/metadata\.json$]
           
            
            markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, extensions = {})
            readmeText = archive.read_entry %r[/README\.(md|markdown)]
            readmeHTML = markdown.render(readmeText)
            parsedJSON = JSON.parse(metadata_file)
            
            parsedJSON["documentation"] = readmeHTML
            parsedJSON
            
        rescue => error
            warn "Error reading from module archive #{archive_path}: #{error}"
            return nil
        end
    end
end
