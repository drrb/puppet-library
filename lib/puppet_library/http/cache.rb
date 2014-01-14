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
        def initialize(millis_to_live = 10 * 1000)
            @reaper = Reaper.new(millis_to_live)
            @cache = {}
        end

        def get(key)
            entry = @cache[key]
            if entry
                return entry.value unless @reaper.wants_to_kill? entry
            end

            value = yield
            @cache[key] = Entry.new(value)
            return value
        end

        class Entry
            attr_accessor :value

            def initialize(value)
                @birth = Time.now
                @value = value
            end

            def age_millis
                age_seconds = Time.now - @birth
                age_seconds * 1000
            end
        end

        class Reaper
            def initialize(millis_to_live)
                @millis_to_live = millis_to_live
            end

            def wants_to_kill?(entry)
                entry.age_millis > @millis_to_live
            end
        end
    end
end
