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
require 'puppet_library/http/cache/in_memory'

module PuppetLibrary::Forge
    # A forge for serving modules from a Git repository
    #
    # <b>Usage:</b>
    #
    #    forge = PuppetLibrary::Forge::GitRepository.configure do
    #        # The location of the git repository
    #        source "http://example.com/mymodule.git"
    #
    #        # A regular expression describing which tags to serve
    #        include_tags /[0-9.]+/
    #    end
    class GitRepository < PuppetLibrary::Forge::Abstract

        def self.configure(&block)
            config_api = PuppetLibrary::Util::ConfigApi.for(GitRepository) do
                required :source, "path or URL"
                required :include_tags, "regex" do |value|
                    value.tap do |value|
                        raise "not a regex" unless value.is_a? Regexp
                    end
                end
            end

            config = config_api.configure(&block)
            cache_dir = PuppetLibrary::Util::TempDir.new("git-repo-cache")
            git = PuppetLibrary::Util::Git.new(config.get_source, cache_dir)
            GitRepository.new(git, config.get_include_tags)
        end

        # * <tt>:source</tt> - The URL or path of the git repository
        # * <tt>:version_tag_regex</tt> - A regex that describes which tags to serve
        def initialize(git, version_tag_regex)
            super(self)
            @version_tag_regex = version_tag_regex
            @git = git
            @modulefile_cache = PuppetLibrary::Http::Cache::InMemory.new(60)
            @tags_cache = PuppetLibrary::Http::Cache::InMemory.new(60)
        end

        def prime
            @git.update_cache!
        end

        def clear_cache
            @git.clear_cache!
        end

        def get_module(author, name, version)
            return nil unless tags.include? tag_for(version)

            metadata = modulefile_for(version).to_metadata
            return nil unless metadata["name"] == "#{author}-#{name}"

            with_tag_for(version) do |tag_path|
                PuppetLibrary::Archive::Archiver.archive_dir(tag_path, "#{metadata["name"]}-#{version}") do |archive|
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
            @tags_cache.get do
                tags = @git.tags
                tags = tags.select {|tag| tag =~ @version_tag_regex }
                tags = tags.select {|tag| @git.file_exists?("Modulefile", tag) }
            end
        end

        def modulefile_for_tag(tag)
            @modulefile_cache.get(tag) do
                modulefile_source = @git.read_file("Modulefile", tag)
                PuppetLibrary::PuppetModule::Modulefile.parse(modulefile_source)
            end
        end

        def modulefile_for(version)
            modulefile_for_tag(tag_for(version))
        end

        def with_tag_for(version, &block)
            @git.with_tag(tag_for(version), &block)
        end

        def tag_for(version)
            tag_versions[version]
        end

        def tag_versions
            tags_to_versions = tags.map do |tag|
                [ modulefile_for_tag(tag).get_version, tag ]
            end
            Hash[tags_to_versions]
        end
    end
end
