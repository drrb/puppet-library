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

require 'puppet_library/module_metadata'
require 'puppet_library/module_repo/multi'

class Array
    def deep_merge
        inject({}) do |merged, map|
            merged.deep_merge(map)
        end
    end
end

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
    class Server < Sinatra::Base

        def initialize(module_repo = ModuleRepo::Multi.new)
            super(nil)
            @repo = settings.respond_to?(:module_repo) ? settings.module_repo : module_repo
        end

        configure do
            enable :logging
        end

        get "/:author/:module.json" do
            author = params[:author]
            module_name = params[:module]

            begin
                get_module_metadata(author, module_name).to_json
            rescue ModuleNotFound
                status 410
                {"error" => "Could not find module \"#{module_name}\""}.to_json
            end
        end

        get "/api/v1/releases.json" do
            author, module_name = params[:module].split "/"
            begin
                get_module_metadata_with_dependencies(author, module_name).to_json
            rescue ModuleNotFound
                status 410
                {"error" => "Module #{author}/#{module_name} not found"}.to_json
            end
        end

        get "/modules/:author-:module-:version.tar.gz" do
            author = params[:author]
            name = params[:module]
            version = params[:version]

            content_type "application/octet-stream"

            begin
                get_module_buffer(author, name, version).tap do
                    attachment "#{author}-#{name}-#{version}.tar.gz"
                end
            rescue ModuleNotFound
                status 404
            end
        end

        private
        def get_module_metadata(author, name)
            modules = get_metadata(author, name)
            raise ModuleNotFound if modules.empty?

            module_infos = modules.map { |m| m.to_info }
            module_infos.deep_merge
        end

        def get_module_metadata_with_dependencies(author, name)
            full_name = "#{author}/#{name}"

            module_queue = []
            modules_versions = {}
            module_queue << full_name
            until module_queue.empty?
                module_full_name = module_queue.shift
                already_added = modules_versions.include? module_full_name
                unless already_added
                    author, module_name = module_full_name.split "/"
                    module_versions = get_metadata(author, module_name)
                    dependencies = module_versions.map {|v| v.dependency_names }.flatten
                    module_queue += dependencies
                    modules_versions[module_full_name] = module_versions.map { |v| v.to_version }
                end
            end
            raise ModuleNotFound if modules_versions.values == [[]]
            modules_versions
        end

        def get_module_buffer(author, name, version)
            @repo.get_module(author, name, version) or raise ModuleNotFound
        end

        def get_metadata(author, module_name)
            @repo.get_metadata(author, module_name).map {|metadata| ModuleMetadata.new(metadata)}
        end
    end
end

class ModuleNotFound < Exception
end
