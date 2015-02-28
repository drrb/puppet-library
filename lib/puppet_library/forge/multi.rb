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
require 'puppet_library/util/patches'
require 'ostruct'

module PuppetLibrary::Forge

    # A forge that delegates to multiple other forges.
    #
    # For queries, all subforges are queried. The results are merged, giving
    # preference to earlier ones. That is, if the same version of a module is
    # found in two different subforges, the one contained in the earlier
    # subforge is kept in the query results.
    #
    # For downloads, subforges are queried sequentially. The first module found
    # is returned.
    #
    # <b>Usage:</b>
    #
    #     # A forge that serves modules from disk, and proxies a remote forge
    #     multi_forge = Multi.new
    #     multi_forge.add_forge(Directory.new("/var/modules"))
    #     multi_forge.add_forge(Proxy.new("http://forge.puppetlabs.com"))
    class Multi < Forge
        def initialize
            @forges = []
        end

        def prime
            @forges.each_in_parallel &:prime
        end

        def clear_cache
            @forges.each_in_parallel &:clear_cache
        end

        # Add another forge to delegate to.
        def add_forge(forge)
            @forges << forge
        end

        def search_modules(query)
            all_results = @forges.map do |forge|
                forge.search_modules(query)
            end.flatten

            SearchResult.merge_by_full_name(all_results)
        end

        def get_module_buffer(author, name, version)
            @forges.each do |forge|
                begin
                    return forge.get_module_buffer(author, name, version)
                rescue ModuleNotFound
                    # Try the next one
                end
            end
            raise ModuleNotFound
        end

        def get_module_metadata(author, name)
            metadata_list = @forges.inject([]) do |metadata_list, forge|
                begin
                    metadata_list << forge.get_module_metadata(author, name)
                rescue ModuleNotFound
                    metadata_list
                end
            end
            raise ModuleNotFound if metadata_list.empty?
            metadata_list.deep_merge.tap do |metadata|
                metadata["releases"] = metadata["releases"].unique_by { |release| release["version"] }
            end
        end

        def get_module_metadata_with_dependencies(author, name, version)
            modules_to_search = [ OpenStruct.new(:author => author, :name => name, :version => version) ]

            already_searched_modules =  []

            metadata_list = []
            while spec = modules_to_search.shift
                if already_searched_modules.include? spec
                    next
                else
                    already_searched_modules << spec
                end

                @forges.each do |forge|
                    begin
                        metadata = forge.get_module_metadata_with_dependencies(spec.author, spec.name, spec.version)

                        # Search all subforges for all versions of the dependencies too
                        modules_to_search += metadata.keys.map do |dep_full_name|
                            dep_author, dep_name = dep_full_name.split("/")
                            OpenStruct.new(:author => dep_author, :name => dep_name, :version => nil)
                        end

                        metadata_list << metadata
                    rescue ModuleNotFound
                        # Try the next one
                    end
                end
            end

            raise ModuleNotFound if metadata_list.empty?
            metadata_list.deep_merge.tap do |metadata|
                metadata.each do |module_name, releases|
                    metadata[module_name] = releases.unique_by { |release| release["version"] }
                end
            end
        end

        def get_modules(query)
            all_results = @forges.map do |forge|
                forge.get_modules(query)
            end.flatten

            SearchResult.merge_by_full_name(all_results)
        end

        def get_releases(author, name)
            metadata_list = @forges.inject([]) do |metadata_list, forge|
                begin
                    metadata_list << forge.get_module_metadata(author, name)
                rescue ModuleNotFound
                    metadata_list
                end
            end
            raise ModuleNotFound if metadata_list.empty?
            metadata_list.deep_merge.tap do |metadata|
                metadata["releases"] = metadata["releases"].unique_by { |release| release["version"] }
            end
        end
    end
end
