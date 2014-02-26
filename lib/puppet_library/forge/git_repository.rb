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
require 'puppet_library/util/temp_dir'
require 'puppet_library/util/config_api'

module PuppetLibrary::Forge
    # A forge for serving modules from a Git repository
    #
    # <b>Usage:</b>
    #
    #    forge = PuppetLibrary::Forge::GitRepository.configure do |repo|
    #        # The location of the git repository
    #        repo.source = "http://example.com/mymodule.git
    #
    #        # A regular expression describing which tags to serve
    #        repo.include_tags = /[0-9.]+/
    #    end
    class GitRepository < PuppetLibrary::Forge::Abstract

        def self.configure(&block)
            config = PuppetLibrary::Util::ConfigApi.configure(GitRepository, :source, :include_tags, &block)
            GitRepository.new(config.get_source, config.get_include_tags)
        end

        # * <tt>:source</tt> - The URL or path of the git repository
        # * <tt>:version_tag_regex</tt> - A regex that describes which tags to serve
        def initialize(source, version_tag_regex)
            super(self)
            cache_path = PuppetLibrary::Util::TempDir.create("git-repo-cache")
            @version_tag_regex = version_tag_regex
            @git = PuppetLibrary::Util::Git.new(source, cache_path)
        end

        def destroy!
            @git.clear_cache!
        end

        def get_module(author, name, version)
            return nil unless tags.include? tag_for(version)

            metadata = modulefile_for(version).to_metadata
            return nil unless metadata["name"] == "#{author}-#{name}"

            on_tag_for(version) do
                PuppetLibrary::Archive::Archiver.archive_dir('.', "#{metadata["name"]}-#{version}") do |archive|
                    archive.add_file("metadata.json", 0644) do |entry|
                        entry.write metadata.to_json
                    end
                end
            end
        end

        def get_all_metadata
            tags.map do |tag|
                modulefile_for_tag(tag).to_metadata
            end
        end

        def get_metadata(author, module_name)
            metadata = get_all_metadata
            metadata.select do |m|
                m["author"] == author
                m["name"] == "#{author}-#{module_name}"
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

        def modulefile_for(version)
            modulefile_for_tag(tag_for(version))
        end

        def on_tag_for(version, &block)
            @git.on_tag(tag_for(version), &block)
        end

        def tag_for(version)
            version
        end
    end
end
