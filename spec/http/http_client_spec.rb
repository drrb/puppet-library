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

module PuppetLibrary::Http
    describe HttpClient do
        let(:client) { HttpClient.new }

        before do
            allow(client).to receive(:open_uri).with("http:://example.com").and_return(StringIO.new("Content"))
        end

        describe "#get" do
            it "calls open() on the provided URL and reads the result" do
                content = client.get("http:://example.com")

                expect(content).to eq "Content"
            end
        end

        describe "#download" do
            it "calls open() on the provided URL" do
                content = client.download("http:://example.com")

                expect(content.read).to eq "Content"
            end
        end
    end
end
