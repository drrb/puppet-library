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

module PuppetLibrary::Forge
    class ModuleNotFound < Exception
    end

    require 'puppet_library/forge/abstract'
    require 'puppet_library/forge/cache'
    require 'puppet_library/forge/directory'
    require 'puppet_library/forge/source_directory'
    require 'puppet_library/forge/forge'
    require 'puppet_library/forge/git_repository'
    require 'puppet_library/forge/multi'
    require 'puppet_library/forge/proxy'
    require 'puppet_library/forge/search_result'
    require 'puppet_library/forge/source'
end
