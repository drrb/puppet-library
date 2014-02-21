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
    describe TempDir do
        describe "#use" do
            it "creates a directory and changes to it for the life of the block" do
                dir_path = nil
                dir_existed_in_block = false
                TempDir.use("xxx") do |path|
                    dir_existed_in_block = File.directory? path
                    dir_path = path
                end
                expect(dir_existed_in_block).to be_true
                expect(File.exist? dir_path).to be_false
            end
        end
    end
end
