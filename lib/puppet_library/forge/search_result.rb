require 'puppet_library/util'

module PuppetLibrary::Forge::SearchResult
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
        [Gem::Version.new(left), Gem::Version.new(right)].max.version
    end
end
