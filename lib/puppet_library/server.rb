# -*- encoding: utf-8 -*-
# Puppet Library
# Copyright (C) 2013 drrb
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

require 'sinatra/base'
require 'json'
require 'rubygems/package'
require 'zlib'

require 'puppet_library/module_repo'

class Hash
    def deep_merge(other)
        merge(other) do |key, old_val, new_val|
            if old_val.instance_of? Array
                old_val + new_val
            else
                new_val
            end
        end
    end
end

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

        def dependency_names
            dependencies.map {|d| d["name"]}
        end

        def to_info
            {
                "author" => author,
                "full_name" => full_name,
                "name" => name,
                "desc" => @metadata["description"],
                "releases" => [ { "version" => version } ]
            }
        end

        def to_version
            {
                "file" => "/modules/#{author}-#{name}-#{version}.tar.gz",
                "version" => version,
                "dependencies" => dependencies.map {|m| [ m["name"], m["version_requirement"] ]}
            }
        end
    end

    class Server < Sinatra::Base

        def initialize(module_repo = ModuleRepo.new("modules"))
            super(nil)
            @repo = module_repo
        end

        configure do
            enable :logging
        end

        get "/:author/:module.json" do
            author = params[:author]
            module_name = params[:module]
            modules = get_metadata(author, module_name)
            if modules.empty?
                status 410
                {"error" => "Could not find module \"#{module_name}\""}.to_json
            else
                modules.map do |metadata|
                    metadata.to_info
                end.inject({}) do |merged, map|
                    merged.deep_merge(map)
                end.to_json
            end
        end

        get "/api/v1/releases.json" do
            full_name = params[:module]
            module_queue = [full_name]
            modules_versions = {}
            while module_full_name = module_queue.shift
                next if modules_versions[module_full_name]
                author, module_name = module_full_name.split "/"
                module_versions = get_metadata(author, module_name)
                dependencies = module_versions.map {|v| v.dependency_names }.flatten
                module_queue += dependencies
                modules_versions[module_full_name] = module_versions.map { |v| v.to_version }
            end

            if modules_versions.values == [[]]
                status 410
                {"error" => "Module #{full_name} not found"}.to_json
            else
                modules_versions.to_json
            end
        end

        get "/modules/:author-:module-:version.tar.gz" do
            file_name = "#{params[:author]}-#{params[:module]}-#{params[:version]}.tar.gz"
            send_file File.join(File.expand_path(settings.module_dir), file_name), :filename => file_name
        end

        def get_metadata(author, module_name)
            @repo.get_metadata(author, module_name).map {|metadata| ModuleMetadata.new(metadata)}
        end
    end
end
