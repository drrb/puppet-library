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

require 'rubygems'
require 'puppet_library'

server = PuppetLibrary::Server.configure do |library|
    Forge = PuppetLibrary::Forge

    # My custom modules
    library.forge Forge::Directory do |forge|
        forge.path = "/var/lib/modules"
    end

    # Unreleased versions from Github
    library.forge Forge::GitRepository do |forge|
        forge.source = "https://github.com/puppetlabs/puppetlabs-apache.git"
        forge.include_tags = /[0-9.]+/
    end

    library.forge Forge::GitRepository do |forge|
        forge.source = "https://github.com/puppetlabs/puppetlabs-concat.git"
        forge.include_tags = /[0-9.]+/
    end

    library.forge Forge::GitRepository do |forge|
        forge.source = "https://github.com/puppetlabs/puppetlabs-stdlib.git"
        forge.include_tags = /[0-9.]+/
    end

    # Everything from The Forge
    library.forge Forge::Proxy do |forge|
        forge.url = "http://forge.puppetlabs.com"
    end
end

run server
