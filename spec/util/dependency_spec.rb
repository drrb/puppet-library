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
    describe Dependency do
        describe "#new" do
            context "when the version contains a dash" do
                it "replaces the dash with '.pre.'" do
                    expect(Dependency.new("x", "1.0.0-rc1")).to eq Dependency.new("x", "1.0.0.pre.rc1")
                end
            end
            context "when the version number has trailing garbage" do
                it "uses the numbers at the beginning" do
                    [ "", "~>", "<", ">", ">=", "<=", "=" ].each do |operator|
                        expect(Dependency.new("x", " #{operator} 123 xyz")).to eq Dependency.new("x", "#{operator} 123")
                    end
                end
            end
            context "when the version is completely garbage" do
                it "pretends the version number is greater than or equal zero" do
                    [ "", "<", ">", ">=", "<=", "=" ].each do |operator|
                        expect(Dependency.new("x", " #{operator} xyz")).to eq Dependency.new("x", ">= 0")
                    end
                end
            end
        end
    end
end
