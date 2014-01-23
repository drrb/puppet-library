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

require 'puppet_library/forge'

module PuppetLibrary::ModuleRepo
    class Multi < PuppetLibrary::Forge
        def initialize
            super(self)
        end

        def repos
            @repos ||= []
        end

        def add_repo(repo)
            repos << repo
        end

        def get_module_buffer(author, name, version)
            repos.each do |repo|
                begin
                    return repo.get_module_buffer(author, name, version)
                rescue PuppetLibrary::ModuleNotFound
                    # Try the next one
                end
            end
            raise PuppetLibrary::ModuleNotFound
        end

        def get_module_metadata(author, name)
            metadata_list = repos.inject([]) do |metadata_list, repo|
                begin
                    metadata_list << repo.get_module_metadata(author, name)
                rescue PuppetLibrary::ModuleNotFound
                    metadata_list
                end
            end
            raise PuppetLibrary::ModuleNotFound if metadata_list.empty?
            metadata_list.deep_merge.tap do |metadata|
                metadata["releases"] = metadata["releases"].unique_by { |release| release["version"] }
            end
        end

        def get_metadata(author, name)
            metadata_list = repos.inject([]) do |metadata_list, repo|
                metadata_list + repo.get_metadata(author, name)
            end
            metadata_list.unique_by { |metadata| metadata["version"] }
        end
    end
end
