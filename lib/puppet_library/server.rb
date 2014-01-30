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
require 'haml'

require 'puppet_library/forge/multi'

module PuppetLibrary
    class Server < Sinatra::Base
        class Config
            def initialize(forge)
                @forge = forge
            end

            def forge(forge)
                @forge.add_forge forge
            end
        end

        def self.set_up(&config_block)
            forge = Forge::Multi.new
            yield(Config.new(forge))
            Server.new(forge)
        end

        def initialize(forge)
            super(nil)
            @forge = forge
        end

        configure do
            enable :logging
            set :haml, :format => :html5
            set :root, File.expand_path("app", File.dirname(__FILE__))
        end

        get "/" do
            modules = @forge.search_modules(nil)

            haml :index, { :locals => { "modules" => modules } }
        end

        get "/modules.json" do
            search_term = params[:q]
            @forge.search_modules(search_term).to_json
        end

        get "/:author/:module.json" do
            author = params[:author]
            module_name = params[:module]

            begin
                @forge.get_module_metadata(author, module_name).to_json
            rescue Forge::ModuleNotFound
                status 410
                {"error" => "Could not find module \"#{module_name}\""}.to_json
            end
        end

        get "/api/v1/releases.json" do
            author, module_name = params[:module].split "/"
            version = params[:version]
            begin
                @forge.get_module_metadata_with_dependencies(author, module_name, version).to_json
            rescue Forge::ModuleNotFound
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
            rescue Forge::ModuleNotFound
                status 404
            end
        end
    end
end
