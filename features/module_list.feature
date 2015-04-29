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

@javascript
Feature: Module list page
    As a user
    I want to see a list of available modules
    So that I can quickly tell what's on the server

    Scenario: Visit the module list page
        When I visit the module list page
        Then I should see "Modules"

    Scenario: See module versions
        Given the "puppetlabs-apache" module is available at version "1.0.0"
        And the "puppetlabs-apache" module is available at version "1.1.0"
        When I visit the module list page
        Then I should see module "puppetlabs-apache" with versions 1.0.0 and 1.1.0

    Scenario: Follow link to module page
        Given the "puppetlabs-apache" module is available at version "1.0.0"
        And the "puppetlabs-apache" module is available at version "1.1.0"
        When I visit the module list page
        And I click on "puppetlabs-apache"
        Then I should be on the module page for "puppetlabs-apache"
