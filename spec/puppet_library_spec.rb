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

require 'spec_helper'

module PuppetLibrary
    describe PuppetLibrary do
        let(:forge) do
            forge = double(Forge::Multi).as_null_object
            allow(Forge::Multi).to receive(:new).and_return(forge)
            return forge
        end
        let(:server) do
            server = double(Server)
            allow(Server).to receive(:new).with(forge).and_return(server)
            return server
        end
        let(:config_file) { Tempfile.new("puppet-library.yml") }
        let(:log) { double('log').as_null_object }
        let(:library) { PuppetLibrary.new(log) }
        let(:default_options) {{ :app => server, :Host => nil, :Port => nil, :server => nil, :daemonize => false, :pid => nil }}

        before do
            allow(Rack::Server).to receive(:start)
        end

        def default_options_with(substitutions)
            default_options.clone.tap do |options|
                substitutions.each do |k, v|
                    options[k] = v
                end
            end
        end

        describe "#go" do
            context "when using a bad option" do
                it "prints the usage" do
                    expect(log).to receive(:puts).with(/invalid option: --die\nUsage:/)

                    library.go(["--die"])
                end
            end

            context "when using no options" do
                it "runs the server with the default options" do
                    expect(Rack::Server).to receive(:start).with(default_options)

                    library.go([])
                end
            end

            context "when using --port option" do
                it "runs the server with the specified port" do
                    expect(Rack::Server).to receive(:start).with(default_options_with(:Port => "8080"))

                    library.go(["--port", "8080"])
                end
            end

            context "when using --server option" do
                it "runs the app on the specified server" do
                    expect(Rack::Server).to receive(:start).with(default_options_with(:server => "thin"))

                    library.go(["--server", "thin"])
                end
            end

            context "when using --bind-host option" do
                it "runs the server with the specified bind host" do
                    expect(Rack::Server).to receive(:start).with(default_options_with(:Host => "localhost"))

                    library.go(["--bind-host", "localhost"])
                end
            end

            context "when using --daemonize option" do
                it "daemonizes the server" do
                    expect(Rack::Server).to receive(:start).with(default_options_with(:daemonize => true))
                    expect(log).to receive(:puts).with(/Daemonizing/)

                    library.go(["--daemonize"])
                end
            end

            context "when using --pidfile option" do
                it "daemonizes and writes a pidfile to the specified location" do
                    expect(Rack::Server).to receive(:start).with(default_options_with(:daemonize => true, :pid => "/var/run/puppet-library.pid"))
                    expect(log).to receive(:puts).with(/Daemonizing/)
                    expect(log).to receive(:puts).with(/Pidfile: \/var\/run\/puppet-library.pid/)

                    library.go(["--pidfile", "/var/run/puppet-library.pid"])
                end
            end

            context "when using --config-file option" do
                it "uses config values from config file as config defaults" do
                    config = {
                        "port" => 4567,
                        "daemonize" => true,
                        "server" => "thin",
                        "pidfile" => "/var/run/puppet-library.pid",
                        "forges" => [
                            { "Directory" => "/var/lib/modules" },
                            { "Proxy" => "http://forge.puppetlabs.com" }
                        ]
                    }
                    File.open(config_file.path, "w") { |f| f << config.to_yaml }
                    expect(Forge::Directory).to receive(:new).with("/var/lib/modules")
                    expect(Forge::Proxy).to receive(:new).with("http://forge.puppetlabs.com")
                    expect(forge).to receive(:add_forge).twice
                    expect(Rack::Server).to receive(:start).with(default_options_with(:Port => 4567, :daemonize => true, :pid => "/var/run/puppet-library.pid", :server => "thin"))

                    library.go(["--config-file", config_file.path])
                end
            end

            context "when using --proxy option" do
                it "adds a proxy module forge for each option specified" do
                    proxy1 = double('proxy1')
                    proxy2 = double('proxy2')
                    expect(Forge::Proxy).to receive(:new).with("http://forge1.example.com").and_return(proxy1)
                    expect(Forge::Proxy).to receive(:new).with("http://forge2.example.com").and_return(proxy2)
                    expect(forge).to receive(:add_forge).with(proxy1)
                    expect(forge).to receive(:add_forge).with(proxy2)
                    expect(Rack::Server).to receive(:start).with(default_options)

                    library.go(["--proxy", "http://forge1.example.com", "--proxy", "http://forge2.example.com"])
                end

                context "when no protocol is specified" do
                    it "defaults to HTTP" do
                        expect(Forge::Proxy).to receive(:new).with("http://forge.example.com")

                        library.go(["--proxy", "forge.example.com"])
                    end
                end

                context "when the URL contains a trailing slash" do
                    it "removes the slash" do
                        expect(Forge::Proxy).to receive(:new).with("http://forge.example.com")

                        library.go(["--proxy", "http://forge.example.com/"])
                    end
                end
            end

            context "when using --cache-basedir option" do
                it "uses the specified directory to hold cache directories for all proxies" do
                    proxy1 = double('proxy')
                    expect(Forge::Cache).to receive(:new).with("http://forge1.example.com", "/var/modules/forge1.example.com").and_return(proxy1)
                    expect(forge).to receive(:add_forge).with(proxy1)
                    expect(Rack::Server).to receive(:start).with(default_options)

                    library.go(["--proxy", "http://forge1.example.com", "--cache-basedir", "/var/modules"])
                end

                it "expands the path specified" do
                    expect(Forge::Cache).to receive(:new).with("http://forge1.example.com", "/var/modules/forge1.example.com")

                    library.go(["--proxy", "http://forge1.example.com", "--cache-basedir", "/var/../var/modules"])
                end
            end

            context "when using --module-dir option" do
                it "adds a directory forge to the server for each module directory" do
                    directory_forge_1 = double("directory_forge_1")
                    directory_forge_2 = double("directory_forge_2")
                    expect(Forge::Directory).to receive(:new).with("dir1").and_return(directory_forge_1)
                    expect(Forge::Directory).to receive(:new).with("dir2").and_return(directory_forge_2)
                    expect(forge).to receive(:add_forge).with(directory_forge_1)
                    expect(forge).to receive(:add_forge).with(directory_forge_2)
                    expect(Rack::Server).to receive(:start).with(default_options)

                    library.go(["--module-dir", "dir1", "--module-dir", "dir2"])
                end
            end

            context "when no proxy URLs or module directories specified" do
                it "proxies the Puppet Forge" do
                    proxy = double("proxy")
                    expect(Forge::Proxy).to receive(:new).with("http://forge.puppetlabs.com").and_return(proxy)
                    expect(forge).to receive(:add_forge).with(proxy)
                    expect(Rack::Server).to receive(:start).with(default_options)

                    library.go([])
                end
            end

            it "logs the server options" do
                expect(log).to receive(:puts).with(/Port: default/)
                expect(log).to receive(:puts).with(/Host: default/)
                expect(log).to receive(:puts).with(/Server: default/)
                expect(log).to receive(:puts).with(/Forges:/)
                expect(log).to receive(:puts).with(/- PuppetLibrary::Forge::Proxy: http:\/\/forge.example.com/)
                library.go(["--proxy", "http://forge.example.com"])
            end
        end
    end
end
