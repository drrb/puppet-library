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

class Array
    def version_sort_on
        sort_by do |element|
            version = yield(element)
            Gem::Version.new(version)
        end
    end
end

module PuppetLibrary::Forge
    class Multi
        def add_forge(forge)
            forges << forge
        end

        def search_modules(query)
            all_results = forges.map do |forge|
                forge.search_modules(query)
            end.flatten

            results_by_module = all_results.group_by do |result|
                result["full_name"]
            end

            results_by_module.values.map do |module_results|
                combine_search_results(module_results)
            end.flatten
        end

        def get_module_buffer(author, name, version)
            forges.each do |forge|
                begin
                    return forge.get_module_buffer(author, name, version)
                rescue ModuleNotFound
                    # Try the next one
                end
            end
            raise ModuleNotFound
        end

        def get_module_metadata(author, name)
            metadata_list = forges.inject([]) do |metadata_list, forge|
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
            metadata_list = []
            forges.each do |forge|
                begin
                    metadata_list << forge.get_module_metadata_with_dependencies(author, name, version)
                rescue ModuleNotFound
                    # Try the next one
                end
            end
            raise ModuleNotFound if metadata_list.empty?
            metadata_list.deep_merge.tap do |metadata|
                metadata.each do |module_name, releases|
                    metadata[module_name] = releases.unique_by { |release| release["version"] }
                end
            end
        end

        private
        def forges
            @forges ||= []
        end

        def combine_search_results(search_results)
            highest_version, tags, releases = search_results.inject([nil, [], []]) do |(highest_version, tags, releases), result|
                [
                    max_version(highest_version, result["version"]),
                    tags + (result["tag_list"] || []),
                    releases + (result["releases"] || [])
                ]
            end

            combined_result = search_results.first.tap do |result|
                result["version"] = highest_version
                result["tag_list"] = tags.uniq
                result["releases"] = releases.uniq.version_sort_on {|r| r["version"]}.reverse
            end
        end

        def max_version(left, right)
            [Gem::Version.new(left), Gem::Version.new(right)].max.version
        end
    end
end
