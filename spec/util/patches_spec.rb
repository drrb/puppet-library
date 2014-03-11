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

describe 'patches' do
    describe Gem::Version do
        describe "#new" do
            context "when the version number contains a dash" do
                it "replaces the dash with '.pre.'" do
                    expect(Gem::Version.new("1.0.0-rc1")).to eq Gem::Version.new("1.0.0.pre.rc1")
                end
            end
            context "when the version number has trailing garbage" do
                it "uses the numbers at the beginning" do
                    expect(Gem::Version.new("123 xyz")).to eq Gem::Version.new("123")
                end
            end
            context "when the version is completely garbage" do
                it "pretends the version number is zero" do
                    expect(Gem::Version.new("xyz")).to eq Gem::Version.new("0")
                end
            end
        end
    end

    describe Array do
        describe "#unique_by" do
            it "behaves like #uniq with a block, but works with Ruby < 1.9" do
                son = { "name" => "john", "age" => 10 }
                dad = { "name" => "john", "age" => 40 }
                mom = { "name" => "jane", "age" => 40 }

                family = [son, dad, mom]
                expect(family.unique_by {|p| p["name"]}).to eq [son, mom]
            end
        end

        describe "#version_sort" do
            it "sorts according to version numbers" do
                expect(["2.0.0", "1.10.0", "1.2.0"].version_sort).to eq ["1.2.0", "1.10.0", "2.0.0"]
            end

            it "copes with odd versions" do
                expect(["1.10.0-badprerelease", "1.3", "1.10.0", "xxx", "1.10.0.rc1", "1.2.0"].version_sort).to eq ["xxx", "1.2.0", "1.3", "1.10.0-badprerelease", "1.10.0.rc1", "1.10.0"]
            end
        end
    end
end
