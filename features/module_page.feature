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

Feature: Module page
    As a user
    I want to see the details of a module
    So that I can tell exactly what's on the server

    Scenario: Visit the module page
        Given the "puppetlabs-apache" module is available at version "1.0.0"
        And the "puppetlabs-apache" module is available at version "1.1.0"
        When I visit the module page for "puppetlabs-apache"
        Then I should see "Author: puppetlabs"
        Then I should see "Name: apache"
        And I should see "1.0.0"
        And I should see "1.1.0"
        And I should see "puppetlabs-apache module, version 1.1.0"

    Scenario: Visit a nonexistant module page
        When I visit the module page for "nonexistant-nonexistant"
        Then I should see 'Module "nonexistant-nonexistant" not found'
