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
require 'docile'

require 'puppet_library/forge/multi'
require 'puppet_library/util/patches'

module PuppetLibrary
    # The Puppet Library server
    #
    # A Rack application that can be configured as follows:
    #
    #    server = PuppetLibrary::Server.configure
    #        # Look for my modules locally
    #        forge :directory do
    #            path "/var/lib/modules"
    #        end
    #
    #        # Get everything else from the Puppet Forge
    #        forge :proxy do
    #            url "http://forge.puppetlabs.com"
    #        end
    #    end
    #
    #    run server
    class Server < Sinatra::Base
        class Config
            def initialize(forge)
                @forge = forge
            end

            def forge(forge, &block)
                if forge.is_a? Symbol
                    class_name = forge.to_s.snake_case_to_camel_case
                    forge_type = Forge.module_eval(class_name)
                    @forge.add_forge forge_type.configure(&block)
                else
                    @forge.add_forge forge
                end
            end
        end

        def self.configure(&block)
            forge = Forge::Multi.new
            Docile.dsl_eval(Config.new(forge), &block)
            Server.new(forge)
        end

        def initialize(forge)
            super(nil)
            @forge = forge
            @forge.prime
        end

        configure do
            enable :logging
            set :haml, :format => :html5
            set :root, File.expand_path("app", File.dirname(__FILE__))
        end

        get "/" do
            query = params[:search]
            haml :index, { :locals => { "query" => query } }
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
                halt 410, {"error" => "Could not find module \"#{module_name}\""}.to_json
            end
        end

        get "/api/v1/releases.json" do
            unless params[:module]
                halt 400, {"error" => "The number of version constraints in the query does not match the number of module names"}.to_json
            end

            author, module_name = params[:module].split "/"
            version = params[:version]
            begin
                @forge.get_module_metadata_with_dependencies(author, module_name, version).to_json
            rescue Forge::ModuleNotFound
                halt 410, {"error" => "Module #{author}/#{module_name} not found"}.to_json
            end
        end

        get "/modules/:author-:module-:version.tar.gz" do
            author = params[:author]
            name = params[:module]
            version = params[:version]

            content_type "application/octet-stream"

            begin
                buffer = @forge.get_module_buffer(author, name, version).tap do
                    attachment "#{author}-#{name}-#{version}.tar.gz"
                end
                download buffer
            rescue Forge::ModuleNotFound
                halt 404
            end
        end

        get "/:author/:module" do
            author = params[:author]
            module_name = params[:module]

            begin
                metadata = @forge.get_module_metadata(author, module_name)
                haml :module, { :locals => { "metadata" => metadata } }
            rescue Forge::ModuleNotFound
                halt 404, haml(:module_not_found, { :locals => { "author" => author, "name" => module_name } })
            end
        end

        post "/api/forge/clear-cache" do
            @forge.clear_cache
        end

        private
        def download(buffer)
            if buffer.respond_to?(:size)
                headers = { "Content-Length" => buffer.size.to_s }
            else
                headers = {}
            end
            [ 200, headers, buffer ]
        end
    end
end
