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

require 'puppet_library/util/patches'
require 'puppet_library/util/version'

module PuppetLibrary::Forge
    module SearchResult
        def self.merge_by_full_name(results)
            results_by_module = results.group_by do |result|
                result["full_name"]
            end

            results_by_module.values.map do |module_results|
                combine_search_results(module_results)
            end.flatten
        end

        def self.combine_search_results(search_results)
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
                result["releases"] = releases.uniq.version_sort_by {|r| r["version"]}.reverse
            end
        end

        def self.max_version(left, right)
            [PuppetLibrary::Util::Version.new(left), PuppetLibrary::Util::Version.new(right)].max.version
        end
    end
end
