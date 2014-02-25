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

require 'puppet_library/forge/proxy'
require 'puppet_library/http/http_client'
module PuppetLibrary::Forge

    # A forge that proxies a remote forge. All module archives downloaded from the
    # remote forged are cached to disk.
    #
    # <b>Usage:</b>
    #
    #    forge = PuppetLibrary::Forge::Cache.configure do |repo|
    #        # The URL of the remote forge
    #        repo.url = "http://forge.example.com
    #
    #        # The path to cache the files to on disk
    #        repo.path = "/var/modules/cache
    #    end
    class Cache < Proxy
        class Config
            attr_accessor :url, :path
        end

        def self.configure
            config = Config.new
            yield(config)
            Cache.new(config.url, config.path)
        end

        # * <tt>:url</tt> - The URL of the remote forge.
        # * <tt>:cache_dir</tt> - The directory in which to cache the downloaded artifacts.
        def initialize(url, cache_dir, http_client = PuppetLibrary::Http::HttpClient.new)
            super(url, PuppetLibrary::Http::Cache::InMemory.new, PuppetLibrary::Http::Cache::Disk.new(cache_dir), http_client)
        end
    end
end
