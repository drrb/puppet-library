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
        TTL_FOREVER = -1

        def initialize(millis_to_live = TTL_FOREVER)
            if millis_to_live == TTL_FOREVER
                @reaper = Reaper.that_never_kills_entries
            else
                @reaper = Reaper.that_kills_entries_older_than(millis_to_live)
            end
        end

        def cache
            @cache ||= {}
        end

        def get(key)
            entry = cache[key]
            if entry && fresh_enough?(entry)
                return entry.value
            else
                value = yield
                cache[key] = Entry.new(value)
                return value
            end
        end

        private
        def fresh_enough?(entry)
            stale = @reaper.wants_to_kill? entry
            return !stale
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
            def self.that_kills_entries_older_than(millis_to_live)
                TimelyReaper.new(millis_to_live)
            end

            def self.that_never_kills_entries
                HoardingReaper.new
            end
        end

        class TimelyReaper
            def initialize(millis_to_live)
                @millis_to_live = millis_to_live
            end

            def wants_to_kill?(entry)
                entry.age_millis > @millis_to_live
            end
        end

        class HoardingReaper
            def wants_to_kill?(entry)
                false
            end
        end
    end
end
