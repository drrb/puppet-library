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
require 'puppet_library/forge'
require 'puppet_library/module_repo/directory'
require 'puppet_library/module_repo/multi'

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

                options[:port] = "9292"
                opts.on("-p", "--port [PORT]", "Port to listen on (defaults to #{options[:port]})") do |port|
                    options[:port] = port
                end

                opts.on("-s", "--server [SERVER]", "Server to use (defaults to whatever Rack wants to use)") do |server|
                    options[:server] = server
                end

                options[:hostname] = "0.0.0.0"
                opts.on("-b", "--bind-host [HOSTNAME]", "Host name to bind to (defaults to #{options[:hostname]})") do |hostname|
                    options[:hostname] = hostname
                end

                options[:repositories] = []
                opts.on("-m", "--module-dir [DIR]", "Directory containing the modules (can be specified multiple times. Defaults to './modules')") do |module_dir|
                    options[:repositories] << [ModuleRepo::Directory, module_dir]
                end
                opts.on("-x", "--proxy [URL]", "Remote forge to proxy (can be specified multiple times)") do |url|
                    options[:repositories] << [ModuleRepo::Proxy, url]
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
            #TODO: maybe don't have a default module directory
            if options[:repositories].empty?
                options[:repositories] << [ ModuleRepo::Directory, "./modules" ]
            end

            module_repo = ModuleRepo::Multi.new
            options[:repositories].each do |(repo_type, config)|
                subrepo = repo_type.new(config)
                module_repo.add_repo(subrepo)
            end
            forge = Forge.new(module_repo)
            Server.new(forge)
        end

        def announce_server_start(options)
            @log.puts "Starting Puppet Library server:"
            @log.puts " |- Port: #{options[:port]}"
            @log.puts " |- Host: #{options[:hostname]}"
            @log.puts " |- Server: #{options[:server] ? options[:server] : 'default'}"
            @log.puts " `- Repositories:"
            options[:repositories].each do |(repo_type, config)|
                @log.puts "    - #{repo_type}: #{config}"
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
