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
    describe Url do
        describe "#normalize" do
            it "leaves normal URLs alone" do
                result = Url.normalize "http://localhost"
                expect(result).to eq "http://localhost"
            end

            it "adds http:// to URI with no scheme" do
                result = Url.normalize "localhost"
                expect(result).to eq "http://localhost"
            end

            it "removes a trailing slash" do
                result = Url.normalize "http://localhost/"
                expect(result).to eq "http://localhost"
            end
        end
    end
end
