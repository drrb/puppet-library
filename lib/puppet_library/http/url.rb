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

require 'uri'

module PuppetLibrary::Http
    class Url
        def self.normalize(uri_string)
            begin
                url = URI.parse(uri_string)
            rescue URI::InvalidURIError => e
                raise PuppetLibrary::ExpectedError, "Invalid URL '#{uri_string}': #{e.message}"
            end
            if url.scheme
                raise PuppetLibrary::ExpectedError, "Invalid URL '#{uri_string}': unsupported protocol '#{url.scheme}'" unless url.scheme =~ /^https?$/
            else
                uri_string = "http://#{uri_string}"
            end
            uri_string.sub /\/$/, ""
        end
    end
end
