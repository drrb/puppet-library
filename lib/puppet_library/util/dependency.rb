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

module PuppetLibrary::Util
    class Dependency < Gem::Dependency
        def initialize(name, spec)
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
end
