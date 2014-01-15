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

require 'sinatra/base'

require 'puppet_library/forge'
require 'puppet_library/module_metadata'
require 'puppet_library/module_repo/multi'

module PuppetLibrary
    class Server < Sinatra::Base

        def initialize(module_repo = ModuleRepo::Multi.new)
            super(nil)
            @repo = settings.respond_to?(:module_repo) ? settings.module_repo : module_repo
            @forge = Forge.new(@repo)
        end

        configure do
            enable :logging
        end

        get "/:author/:module.json" do
            author = params[:author]
            module_name = params[:module]

            begin
                @forge.get_module_metadata(author, module_name).to_json
            rescue ModuleNotFound
                status 410
                {"error" => "Could not find module \"#{module_name}\""}.to_json
            end
        end

        get "/api/v1/releases.json" do
            author, module_name = params[:module].split "/"
            begin
                @forge.get_module_metadata_with_dependencies(author, module_name).to_json
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
                @forge.get_module_buffer(author, name, version).tap do
                    attachment "#{author}-#{name}-#{version}.tar.gz"
                end
            rescue ModuleNotFound
                status 404
            end
        end
    end
end
