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

module PuppetLibrary::Util
    describe Version do
        describe "#new" do
            context "when the version number contains a dash" do
                it "replaces the dash with '.pre.'" do
                    expect(Version.new("1.0.0-rc1")).to eq Version.new("1.0.0.pre.rc1")
                end
            end
            context "when the version number has trailing garbage" do
                it "uses the numbers at the beginning" do
                    expect(Version.new("123 xyz")).to eq Version.new("123")
                end
            end
            context "when the version is completely garbage" do
                it "pretends the version number is zero" do
                    expect(Version.new("xyz")).to eq Version.new("0")
                end
            end
        end
    end
end
