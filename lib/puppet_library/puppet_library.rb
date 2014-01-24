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

require 'rack'
require 'puppet_library/forge/directory'
require 'puppet_library/forge/multi'

module PuppetLibrary
    class PuppetLibrary
        def initialize(log = STDERR)
            @log = log
        end

        def go(args)
            options = parse_options(args)
            server = build_server(options)
            announce_server_start(options)

            start_server(server, options)
        rescue ExpectedError => error
            @log.puts "Error: #{error}"
        end

        private
        def parse_options(args)
            options = {}
            option_parser = OptionParser.new do |opts|
                opts.banner = "Usage: #{File.basename $0} [options]"

                opts.on("-p", "--port [PORT]", "Port to listen on (defaults to whatever Rack wants to use)") do |port|
                    options[:port] = port
                end

                opts.on("-s", "--server [SERVER]", "Server to use (defaults to whatever Rack wants to use)") do |server|
                    options[:server] = server
                end

                opts.on("-b", "--bind-host [HOSTNAME]", "Host name to bind to (defaults to whatever Rack wants to use)") do |hostname|
                    options[:hostname] = hostname
                end

                options[:forges] = []
                opts.on("-m", "--module-dir [DIR]", "Directory containing the modules (can be specified multiple times. Defaults to './modules')") do |module_dir|
                    options[:forges] << [Forge::Directory, module_dir]
                end
                opts.on("-x", "--proxy [URL]", "Remote forge to proxy (can be specified multiple times)") do |url|
                    options[:forges] << [Forge::Proxy, url]
                end
            end
            begin
                option_parser.parse(args)
            rescue OptionParser::InvalidOption => parse_error
                raise ExpectedError, parse_error.message + "\n" + option_parser.help
            end

            return options
        end

        def build_server(options)
            if options[:forges].empty?
                options[:forges] << [ Forge::Proxy, "http://forge.puppetlabs.com" ]
            end

            Server.set_up do |server|
                options[:forges].each do |(forge_type, config)|
                    subforge = forge_type.new(config)
                    server.forge subforge
                end
            end
        end

        def announce_server_start(options)
            options = options.clone
            options.default = "default"
            @log.puts "Starting Puppet Library server:"
            @log.puts " |- Port: #{options[:port]}"
            @log.puts " |- Host: #{options[:hostname]}"
            @log.puts " |- Server: #{options[:server]}"
            @log.puts " `- Forges:"
            options[:forges].each do |(forge_type, config)|
                @log.puts "    - #{forge_type}: #{config}"
            end
        end

        def start_server(server, options)
            Rack::Server.start(
                :app => server,
                :Host => options[:hostname],
                :Port => options[:port],
                :server => options[:server]
            )
        end
    end

    class ExpectedError < StandardError
    end
end
