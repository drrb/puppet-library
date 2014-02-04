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

require 'simplecov' unless RUBY_VERSION.start_with? "1.8"
require 'puppet_library'
require 'module_spec_helper'
require 'pry'
require 'rack'
require 'tempfile'
require 'fileutils'

include FileUtils

class Tempdir
    attr_reader :path

    def self.create(name)
        Tempdir.new(name).path
    end

    def initialize(name)
        file = Tempfile.new(name)
        @path = file.path
        file.unlink
        FileUtils.mkdir @path
    end
end
