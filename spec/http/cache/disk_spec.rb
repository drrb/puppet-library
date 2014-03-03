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

module PuppetLibrary::Http::Cache
    describe Disk do
        let(:cache_dir) { Tempdir.new("modulecache").path }
        let(:cache) { Disk.new(cache_dir) }

        after do
            rm_rf cache_dir
        end

        describe "#get" do
            context "the first time it's called" do
                it "returns the value from the block" do
                    buffer = StringIO.new "hello"

                    result = cache.get("my-file") { buffer }

                    expect(result.read).to eq "hello"
                end

                it "saves the content to disk" do
                    buffer = StringIO.new "hello"

                    result = cache.get("dir/my-file") { buffer }

                    path = File.join(cache_dir, "dir", "my-file")
                    expect(File.read(path)).to eq "hello"
                end
            end

            context "the second time it's called" do
                it "reads the config from the disk" do
                    cache.get("my-file") { StringIO.new "hello" }
                    result = cache.get("my-file") { raise "shouldn't be called" }
                end
            end
        end

        describe "#clear" do
            it "clears the cache" do
                cache.get("dir/my-file") { StringIO.new "1" }
                cache.clear
                result = cache.get("dir/my-file") { StringIO.new "2" }
                expect(result.read).to eq "2"
            end
        end
    end
end
