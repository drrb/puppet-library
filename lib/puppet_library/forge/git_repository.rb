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
require 'zlib'
require 'open3'
require 'rubygems/package'
require 'puppet_library/forge/abstract'
require 'puppet_library/util/git'

module PuppetLibrary::Forge
    class GitRepository < PuppetLibrary::Forge::Abstract
        def initialize(author, name, version_tag_regex, git_path)
            super(self)
            @author = author
            @name = name
            @path = File.expand_path(git_path)
            @version_tag_regex = version_tag_regex
            @git = PuppetLibrary::Util::Git.new(git_path)
        end

        def get_module(author, name, version)
            unless author == @author && name == @name
                return nil
            end
            unless tags.include? tag_name(version)
                return nil
            end
            on_tag_for(version) do
                PuppetLibrary::Archive::Archiver.archive_dir(@path, "#{@author}-#{@name}-#{version}") do |archive|
                    archive.add_file("metadata.json", 0644) do |entry|
                        entry.write modulefile.to_metadata.to_json
                    end
                end
            end
        end

        def get_all_metadata
            get_metadata(@author, @name)
        end

        def get_metadata(author, module_name)
            unless author == @author && module_name == @name
                return []
            end
            tags.map do |tag|
                modulefile_for_tag(tag).to_metadata
            end
        end

        private
        def tags
            @git.tags.select {|tag| tag =~ @version_tag_regex }
        end

        def modulefile_for_tag(tag)
            modulefile_source = @git.read_file("Modulefile", tag)
            PuppetLibrary::PuppetModule::Modulefile.parse(modulefile_source)
        end

        def modulefile
            modulefile_source = @git.read_file("Modulefile")
            PuppetLibrary::PuppetModule::Modulefile.parse(modulefile_source)
        end

        def on_tag_for(version, &block)
            @git.on_tag(tag_name(version), &block)
        end

        def tag_name(version)
            version
        end
    end
end
