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

require 'spec_helper'

module PuppetLibrary
    describe PuppetLibrary do
        let(:module_repo) do
            module_repo = double(ModuleRepo::Multi)
            allow(ModuleRepo::Multi).to receive(:new).and_return(module_repo)
            return module_repo
        end
        let(:server) do
            server = double(Server)
            allow(Server).to receive(:new).and_return(server)
            return server
        end
        let(:log) { double('log').as_null_object }
        let(:library) { PuppetLibrary.new(log) }
        let(:default_options) {{ :app => server, :Host => "0.0.0.0", :Port => "9292"}}
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
            context "when specifying no options" do
                it "runs the server with the default options" do
                    expect(Rack::Server).to receive(:start).with(default_options)

                    library.go([])
                end
            end

            context "when specifying --port option" do
                it "runs the server with the specified port" do
                    expect(Rack::Server).to receive(:start).with(default_options_with(:Port => "8080"))

                    library.go(["--port", "8080"])
                end
            end

            context "when specifying --bind-host option" do
                it "runs the server with the specified bind host" do
                    expect(Rack::Server).to receive(:start).with(default_options_with(:Host => "localhost"))

                    library.go(["--bind-host", "localhost"])
                end
            end

            it "adds a module repository to the server for each module directory" do
                expect(Server).to receive(:new).with(module_repo).and_return(server)
                expect(module_repo).to receive(:add_repo).twice
                expect(Rack::Server).to receive(:start).with(default_options)

                library.go(["--module-dir", "dir1", "--module-dir", "dir2"])
            end

            it "logs the server options" do
                expect(log).to receive(:puts).with(/Port: 9292/)
                expect(log).to receive(:puts).with(/Host: 0\.0\.0\.0/)
                library.go([])
            end
        end
    end
end
