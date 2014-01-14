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
    describe Cache do

        let(:cache) { Cache.new }

        describe "#get" do
            context "the first time it's called" do
                it "returns the value from the provided block" do
                    greeting = cache.get("greeting") { "hello" }

                    expect(greeting).to eq "hello"
                end
            end

            context "the second time it's called" do
                it "returns the cached value" do
                    cache.get("greeting") { "hello" }
                    greeting = cache.get("greeting") { "hi" }

                    expect(greeting).to eq "hello"
                end
            end

            context "when the cached value is falsey" do
                it "returns the cached value" do
                    cache.get("greeting") { false }
                    greeting = cache.get("greeting") { true }

                    expect(greeting).to be_false
                end
            end

            context "when the time limit has expired" do
                it "looks up the value again" do
                    cache = Cache.new(0)

                    greeting = cache.get("greeting") { "hi" }
                    greeting = cache.get("greeting") { "bye" }
                    expect(greeting).to eq "bye"
                end
            end
        end
    end
end
