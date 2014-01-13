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

module PuppetLibrary::ModuleRepo
    class Proxy
        def initialize(url, http_client = PuppetLibrary::Http::HttpClient.new)
            @url = url
            @http_client = http_client
        end

        def get_module(author, name, version)
            versions = proxy_releases_query(author, name)
            module_versions = versions["#{author}/#{name}"]
            module_info = module_versions.find do |v|
                v["version"] == version
            end
            if module_info.nil?
                nil
            else
                download_file(module_info["file"])
            end
        end

        def get_metadata(author, name)
            versions = proxy_releases_query(author, name)

            module_versions = versions["#{author}/#{name}"]
            module_versions.map do |version|
                dependencies = version["dependencies"].map do |(dep_name, dep_spec)|
                    { "name" => dep_name, "version_requirement" => dep_spec }
                end
                {
                    "name" => "#{author}-#{name}",
                    "author" => author,
                    "version" => version["version"],
                    "dependencies" => dependencies
                }
            end
        rescue OpenURI::HTTPError => http_error
            return []
        end

        private
        def proxy_releases_query(author, name)
            get("/api/v1/releases.json?module=#{author}/#{name}")
        end

        def download_file(file)
            @http_client.download(url(file))
        end

        def get(relative_url)
            JSON.parse(@http_client.get(url(relative_url)))
        end

        def url(relative_url)
            #TODO: do this properly
            @url + relative_url
        end
    end
end
