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
            #TODO: this fails for 1.1.0rc1
            version.split('.').map {|part| part.to_i}
        end
    end
end

module PuppetLibrary::Forge
    class Multi
        def add_forge(forge)
            forges << forge
        end

        def search_modules(query)
            results = {}
            forges.each do |forge|
                search_results = forge.search_modules(query)
                search_results.each do |result|
                    module_results = results[result["full_name"]] ||= []
                    module_results << result
                end
            end
            results.values.map do |module_results|
                max_version = module_results.max_by do |r|
                    r["version"]
                end["version"]

                tags = module_results.inject([]) do |tags, result|
                    result_tags = result["tag_list"] || []
                    (tags + result_tags).uniq
                end

                releases = module_results.inject([]) do |releases, result|
                    result_releases = result["releases"] || []
                    (releases + result_releases).uniq
                end.version_sort_on do |release|
                    release["version"]
                end.reverse

                res = module_results.first
                res["version"] = max_version
                res["tag_list"] = tags
                res["releases"] = releases
                res
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
    end
end
