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

require 'puppet_library/archive/archiver'
require 'puppet_library/forge/abstract'
require 'puppet_library/puppet_module/modulefile'
require 'json'

module PuppetLibrary::Forge

    # A forge that serves a module from its source on disk.
    # Metadata (+metadata.json+) is generated on the fly.
    #
    # <b>Note:</b>
    # The module directory must have a +Modulefile+.
    class Source < PuppetLibrary::Forge::Abstract
        def self.configure(&block)
            config_api = PuppetLibrary::Util::ConfigApi.for(Source) do
                required :path, "path to the module's source"
            end
            config = config_api.configure(&block)
            Source.new(Dir.new(config.get_path))
        end

        CACHE_TTL_MILLIS = 500

        # * <tt>:module_dir</tt> - The directory containing the module's source.
        def initialize(module_dir)
            super(self)
            raise "Module directory '#{module_dir.path}' doesn't exist" unless File.directory? module_dir.path
            raise "Module directory '#{module_dir.path}' isn't readable" unless File.executable? module_dir.path
            @module_dir = module_dir
            @cache = PuppetLibrary::Http::Cache::InMemory.new(CACHE_TTL_MILLIS)
        end

        def get_module(author, name, version)
            return nil unless this_module?(author, name, version)
            PuppetLibrary::Archive::Archiver.archive_dir(@module_dir.path, "#{author}-#{name}-#{version}") do |archive|
                archive.add_file("metadata.json", 0644) do |entry|
                    entry.write modulefile.to_metadata.to_json
                end
            end
        end

        def get_metadata(author, module_name)
            return [] unless this_module?(author, module_name)
            [ modulefile.to_metadata ]
        end

        def get_all_metadata
            get_metadata(modulefile.get_author, modulefile.get_simple_name)
        end

        private
        def this_module?(author, module_name, version = nil)
            same_module = modulefile.get_name == "#{author}-#{module_name}"
            if version.nil?
                return same_module
            else
                return same_module && modulefile.get_version == version
            end
        end

        def modulefile
            modulefile_path = File.join(@module_dir.path, "Modulefile")
            @cache.get modulefile_path do
                PuppetLibrary::PuppetModule::Modulefile.read(modulefile_path)
            end
        end
    end
end

