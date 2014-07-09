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

require 'optparse'
require 'rack'
require 'yaml'
require 'puppet_library/forge/source_directory'
require 'puppet_library/forge/directory'
require 'puppet_library/forge/multi'
require 'puppet_library/forge/proxy'
require 'puppet_library/forge/source'
require 'puppet_library/version'

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
                opts.version = VERSION

                opts.on("-c", "--config-file FILE", "Config file to read config values from") do |config_file|
                    options[:config_file] = config_file
                end

                opts.on("-p", "--port PORT", "Port to listen on (defaults to whatever Rack wants to use)") do |port|
                    options[:port] = port
                end

                opts.on("-s", "--server SERVER", "Server to use (defaults to whatever Rack wants to use)") do |server|
                    options[:server] = server
                end

                opts.on("-b", "--bind-host HOSTNAME", "Host name to bind to (defaults to whatever Rack wants to use)") do |hostname|
                    options[:hostname] = hostname
                end

                opts.on("--daemonize", "Run the server in the background") do
                    options[:daemonize] = true
                end

                opts.on("--pidfile FILE", "Write a pidfile to this location after starting (implies --daemonize)") do |pidfile|
                    options[:daemonize] = true
                    options[:pidfile] = File.expand_path pidfile
                end

                options[:forges] = []
                opts.on("-m", "--module-dir DIR", "Directory containing packaged modules (can be specified multiple times)") do |module_dir|
                    options[:forges] << [Forge::Directory, module_dir]
                end
                opts.on("-x", "--proxy URL", "Remote forge to proxy (can be specified multiple times)") do |url|
                    options[:forges] << [Forge::Proxy, sanitize_url(url)]
                end
                opts.on("--source-dir DIR", "Directory containing a module's source (can be specified multiple times)") do |module_dir|
                    options[:forges] << [Forge::Source, module_dir]
                end

                opts.on("--cache-basedir DIR", "Cache all proxies' downloaded modules under this directory") do |cache_basedir|
                    options[:cache_basedir] = cache_basedir
                end
                
                #new option --modulepath
                opts.on("--modulepath DIR", "Directory containing all module's sources") do |modulepath|
                    options[:forges] << [Forge::SourceDirectory, modulepath]
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
            if options[:config_file]
                load_config!(options)
            end

            load_defaults!(options)
            process_options!(options)

            Server.configure do
                options[:forges].each do |(forge_type, config)|
                    forge forge_type.new(*config)
                end
            end
        end

        def announce_server_start(options)
            options = options.clone
            options.default = "default"
            action = options[:daemonize] ? "Daemonizing" : "Starting"
            @log.puts "#{action} Puppet Library server:"
            @log.puts " |- Port: #{options[:port]}"
            @log.puts " |- Host: #{options[:hostname]}"
            @log.puts " |- Pidfile: #{options[:pidfile]}" if options[:pidfile]
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
                :server => options[:server],
                :daemonize => options[:daemonize],
                :pid => options[:pidfile]
            )
        end

        def load_config!(options)
            config = read_yaml_file(options[:config_file])
            options[:daemonize] = config["daemonize"]
            options[:port] = config["port"]
            options[:pidfile] = config["pidfile"]
            options[:server] = config["server"]

            forges_config = config["forges"] || []
            configured_forges = forges_config.map do |forge|
                [ Forge.const_get(forge.keys.first), forge.values.first ]
            end
            options[:forges] = configured_forges + options[:forges]
        end

        def load_defaults!(options)
            options[:daemonize] ||= false
            options[:pidfile] ||= nil
            if options[:forges].empty?
                options[:forges] << [ Forge::Proxy, "http://forge.puppetlabs.com" ]
            end
        end

        def process_options!(options)
            options[:forges].map! do |(forge_type, config)|
                if [ Forge::Directory, Forge::Source, Forge::SourceDirectory ].include? forge_type
                    [ forge_type, [ Dir.new(sanitize_path(config)) ]]
                elsif forge_type == Forge::Proxy && options[:cache_basedir]
                    cache_dir = File.join(options[:cache_basedir], url_hostname(config))
                    path = sanitize_path(cache_dir)
                    FileUtils.mkdir_p path
                    dir = Dir.new(path)
                    [ Forge::Cache, [ config, dir ] ]
                else
                    [ forge_type, config ]
                end
            end
        end

        def read_yaml_file(path)
            YAML.load_file(File.expand_path(path)) || {}
        end

        def sanitize_url(url)
            Http::Url.normalize(url)
        end

        def sanitize_path(path)
            File.expand_path path
        end

        def url_hostname(url)
            URI.parse(Http::Url.normalize(url)).host
        end
    end

    class ExpectedError < StandardError
    end
end
