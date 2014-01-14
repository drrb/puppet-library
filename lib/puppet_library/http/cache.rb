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

module PuppetLibrary::Http
    class Cache
        def cache
            @cache ||= {}
        end

        def get(key)
            entry = cache[key]
            if entry
                return entry.value
            else
                value = yield
                cache[key] = Entry.new(value)
                return value
            end
        end

        class Entry
            attr_accessor :value

            def initialize(value)
                @value = value
            end
        end
    end
end
