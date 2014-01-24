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

require 'puppet_library/http/http_client'
require 'puppet_library/http/cache/in_memory'
require 'puppet_library/http/cache/noop'
require 'puppet_library/http/url'

module PuppetLibrary::Forge
    class Proxy
        def initialize(url,
                       query_cache = PuppetLibrary::Http::Cache::InMemory.new,
                       download_cache = PuppetLibrary::Http::Cache::NoOp.new,
                       http_client = PuppetLibrary::Http::HttpClient.new)
            @url = PuppetLibrary::Http::Url.normalize(url)
            @http_client = http_client
            @query_cache = query_cache
            @download_cache = download_cache
        end

        def search_modules(query)
            results = get("/modules.json?q=#{query}")
            JSON.parse results
        end

        def get_module_buffer(author, name, version)
            begin
                version_info = get_module_version(author, name, version)
                raise ModuleNotFound if version_info.nil?
                download_file(version_info["file"])
            rescue OpenURI::HTTPError
                raise ModuleNotFound
            end
        end

        def get_module_metadata(author, name)
            begin
                response = get("/#{author}/#{name}.json")
                JSON.parse(response)
            rescue OpenURI::HTTPError
                raise ModuleNotFound
            end
        end

        def get_module_metadata_with_dependencies(author, name, version)
            begin
                look_up_releases(author, name, version)
            rescue OpenURI::HTTPError
                raise ModuleNotFound
            end
        end

        private
        def get_module_version(author, name, version)
            module_versions = get_module_versions(author, name)
            module_versions.find do |version_info|
                version_info["version"] == version
            end
        end

        def get_module_versions(author, name)
            versions = look_up_releases(author, name)
            versions["#{author}/#{name}"]
        end

        def look_up_releases(author, name, version = nil)
            version_query = version ? "&version=#{version}" : ""
            url = "/api/v1/releases.json?module=#{author}/#{name}#{version_query}"
            response = get(url)
            JSON.parse(response)
        end

        def download_file(file)
            @download_cache.get(file) do
                @http_client.download(url(file))
            end
        end

        def get(relative_url)
            @query_cache.get(relative_url) do
                @http_client.get(url(relative_url))
            end
        end

        def url(relative_url)
            @url + relative_url
        end
    end
end

