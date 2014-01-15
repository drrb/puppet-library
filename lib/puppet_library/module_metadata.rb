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

module PuppetLibrary
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

        def description
            @metadata["description"]
        end

        def dependency_names
            dependencies.map {|d| d["name"]}
        end

        def to_info
            {
                "author" => author,
                "full_name" => full_name,
                "name" => name,
                "desc" => description,
                "releases" => [ { "version" => version } ]
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
    end
end
