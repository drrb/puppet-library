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

spec_path = File.expand_path("../../spec", File.dirname(__FILE__))
$LOAD_PATH.unshift spec_path unless $LOAD_PATH.include? spec_path

require 'module_spec_helper'
require 'fileutils'

include FileUtils

def module_dir
    unless @module_dir
        file = Tempfile.new("module_dir")
        @module_dir = file.path
        file.delete
    end
    @module_dir
end

def module_writer
    @module_writer ||= ModuleSpecHelper::ModuleWriter.new(module_dir)
end

Before do
    mkdir_p module_dir
    forge.add_forge PuppetLibrary::Forge::Directory.new(module_dir)
end

After do
    rm_rf module_dir
end

Given /^the "(.*?)" module is available at version "(.*?)"$/ do |full_name, version|
    author, name = full_name.split "/"
    module_writer.write_module(author, name, version)
end

When /^I visit the module list page$/ do
    visit "/"
end

When /^I visit the module page for "(.*?)"$/ do |module_name|
    visit "/#{module_name}"
end

Then /^I should see "(.*?)"$/ do |text|
    expect(page).to have_content text
end

Then /^I should see '(.*?)'$/ do |text|
    expect(page).to have_content text
end

Then /^I should see module "(.*?)" with versions? (.*)$/ do |full_name, versions|
    versions = versions.split /\s*,\s*|\s*,?\s*and\s*/
    versions.each do |version|
        find(:xpath, "//li[contains(.,'#{full_name}')]").should have_content version
    end
end
