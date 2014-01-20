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

require 'rubygems/package'

class Array
    # Like 'uniq' with a block, but also works on Ruby < 1.9
    def unique_by
        attr_to_element = {}
        select do |element|
            attribute = yield(element)
            is_duplicate = attr_to_element.include? attribute
            unless is_duplicate
                attr_to_element[attribute] = element
            end
            !is_duplicate
        end
    end
end

class Gem::Package::TarReader
    # Old versions of RubyGems don't include Enumerable in here
    def find
        each do |entry|
            if yield(entry)
                return entry
            end
        end
    end
end
