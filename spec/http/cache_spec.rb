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
                    greeting = cache.get("greeting") do
                        "hello"
                    end

                    expect(greeting).to eq "hello"
                end
            end

            context "the second time it's called" do
                it "returns the cached value" do
                    cache.get("greeting") do
                        "hello"
                    end
                    greeting = cache.get("greeting") do
                        "hi"
                    end

                    expect(greeting).to eq "hello"
                end
            end

            context "when the cached value is falsey" do
                it "returns the cached value" do
                    cache.get("greeting") do
                        false
                    end
                    greeting = cache.get("greeting") do
                        true
                    end

                    expect(greeting).to be_false
                end
            end
        end
    end
end
