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

require 'rack'
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

                options[:hostname] = "0.0.0.0"
                opts.on("-b", "--bind-host [HOSTNAME]", "Host name to bind to (defaults to #{options[:hostname]})") do |hostname|
                    options[:hostname] = hostname
                end

                options[:module_dirs] = []
                opts.on("-m", "--module-dir [DIR]", "Directory containing the modules (can be specified multiple times. Defaults to './modules')") do |module_dir|
                    options[:module_dirs] << module_dir
                end
            end
            begin
                option_parser.parse(args)
            rescue OptionParser::InvalidOption => parse_error
                raise ExpectedError, parse_error.message + "\n" + option_parser.help
            end

            if options[:module_dirs].empty?
                options[:module_dirs] << "./modules"
            end

            return options
        end

        def build_server(options)
            module_repo = ModuleRepo::Multi.new
            options[:module_dirs].each do |dir|
                subrepo = ModuleRepo::Directory.new(dir)
                module_repo.add_repo(subrepo)
            end
            Server.new(module_repo)
        end

        def announce_server_start(options)
            @log.puts "Starting Puppet Library server:"
            @log.puts " |- Port: #{options[:port]}"
            @log.puts " |- Host: #{options[:hostname]}"
            @log.puts " `- Module dirs:"
            options[:module_dirs].each do |dir|
                @log.puts "    - #{dir}"
            end
        end

        def start_server(server, options)
            Rack::Server.start(
                :app => server,
                :Host => options[:hostname],
                :Port => options[:port]
            )
        end
    end

    class ExpectedError < StandardError
    end
end
