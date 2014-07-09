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

require 'puppet_library/forge/forge'
require 'puppet_library/forge/search_result'
require 'puppet_library/util/dependency'
require 'puppet_library/util/patches'

module PuppetLibrary::Forge

    # An abstract forge implementation that makes it easier to create new forge
    # types.
    #
    # See PuppetLibrary::Forge::Directory for an example
    class Abstract < Forge
        def initialize(module_repo)
            @repo = module_repo
        end

        def search_modules(query)
            search = Search.new(query)

            search_results = retrieve_all_metadata.select do |result|
                search.matches? result
            end.sort_by do |result|
                result.version
            end.reverse.map do |result|
                result.to_search_result
            end

            SearchResult.merge_by_full_name(search_results)
        end

        def get_module_metadata(author, name)
            modules = retrieve_metadata(author, name)

            raise ModuleNotFound if modules.empty?

            modules = modules.version_sort_by { |m| m.version }
            module_infos = modules.map { |m| m.to_info }
            module_infos.deep_merge
        end

        def get_module_metadata_with_dependencies(author, name, version)
            raise ModuleNotFound if retrieve_metadata(author, name).empty?

            full_name = "#{author}/#{name}"
            versions = collect_dependencies_versions(full_name)
            return versions if version.nil?

            versions[full_name] = versions[full_name].select do |v|
                PuppetLibrary::Util::Dependency.new(name, version).match?(name, v["version"])
            end

            dependencies = versions[full_name].map do |v|
                v["dependencies"].map {|(name, spec)| name}
            end.flatten
            versions = Hash[versions.select do |name, info|
                name == full_name || dependencies.include?(name)
            end]
            return versions
        end

        def collect_dependencies_versions(module_full_name, metadata = {})
            author, module_name = module_full_name.split "/"
            module_versions = retrieve_metadata(author, module_name)
            metadata[module_full_name] = module_versions.map {|v| v.to_version }

            dependencies = module_versions.map {|v| v.dependency_names }.flatten
            dependencies.each do |dependency|
                collect_dependencies_versions(dependency, metadata) unless metadata.include? dependency
            end
            return metadata
        end

        def get_module_buffer(author, name, version)
            @repo.get_module(author, name, version) or raise ModuleNotFound
        end

        def retrieve_metadata(author, module_name)
            @repo.get_metadata(author, module_name).map {|metadata| ModuleMetadata.new(metadata)}
        end

        def retrieve_all_metadata
            @repo.get_all_metadata.map {|metadata| ModuleMetadata.new(metadata)}
        end
    end

    class Search
        def initialize(query)
            @query = query
        end

        def matches?(metadata)
            return true if @query.nil?
            return true if metadata.name.include? @query
            return true if metadata.author.include? @query
            return false
        end
    end

    class ModuleMetadata
        def initialize(metadata)
            @metadata = metadata
        end

        def author
            @metadata["name"][/^[^-]+/]
        end

        def name
            @metadata["name"].sub(/^[^-]+-/, "")
        end

        def full_name
            @metadata["name"].sub("-", "/")
        end

        def version
            @metadata["version"]
        end

        def dependencies
            @metadata["dependencies"]
        end

        def summary
            @metadata["summary"]
        end

        def description
            @metadata["description"]
        end

        def project_page
            @metadata["project_page"]
        end

        def dependency_names
            dependencies.map {|d| d["name"]}
        end
        
        def documentation
            @metadata["documentation"]
        end

        def to_info
            {
                "author" => author,
                "full_name" => full_name,
                "name" => name,
                "desc" => description,
                "releases" => [ { "version" => version } ],
                "documentation" => documentation
            }
        end

        def to_version
            {
                "file" => "/modules/#{author}-#{name}-#{version}.tar.gz",
                "version" => version,
                "dependencies" => dependencies.map do |dependency|
                    [ dependency["name"], dependency["version_requirement"] ]
                end
            }
        end

        def to_search_result
            {
                "author" => author,
                "full_name" => full_name,
                "name" => name,
                "desc" => summary,
                "project_url" => project_page,
                "releases" => [{ "version" => version}],
                "version" => version,
                "tag_list" => [author, name]
            }
        end
    end
end
