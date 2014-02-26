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

# Early versions of Rubygems have problems with version numbers with dashes
# (e.g. "1.0.0-rc1"). This adds the behaviour or new RG versions to all
# versions, hopefully without breaking newer versions. In most cases we want to
# fail silently with bad version numbers so that we don't crash the server
# because of weird stuff from a remote forge or elsewhere.
module Gem
    def Version.new(version)
        super(version.to_s.gsub("-",".pre."))
    rescue ArgumentError
        # If it starts with numbers, use those
        if version =~ /^\d+(\.\d+)*/
            super(version[/^\d+(\.\d+)*/])
        # Somebody's really made a mess of this version number
        else
            super("0")
        end
    end

    def Dependency.new(name, spec)
        super(name, spec.to_s.gsub("-", ".pre."))
    rescue ArgumentError
        # If it starts with numbers, use those
        if spec =~ /^([~><= ]+)?\d+(\.\d+)*/
            super(name, spec[/^([~><= ]+)?\d+(\.\d+)*/])
        # Somebody's really made a mess of this version number
        else
            super(name, ">= 0")
        end
    end
end

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

    def version_sort
        version_sort_by { |e| e }
    end

    def version_sort_by
        sort_by do |element|
            version = yield(element)
            Gem::Version.new(version)
        end
    end

    def deep_merge
        inject({}) do |merged, map|
            merged.deep_merge(map)
        end
    end
end

class Hash
    def deep_merge(other)
        merge(other) do |key, old_val, new_val|
            if old_val.instance_of? Array
                old_val + new_val
            else
                new_val
            end
        end
    end
end

class String
    def snake_case_to_camel_case
        split("_").map(&:capitalize).join
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
