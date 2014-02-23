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

RSpec::Matchers.define :be_cached do
    match do |mod_file|
        ! Dir[File.join(cache_dir, mod_file)].empty?
    end
end

RSpec::Matchers.define :be_installed do
    match do |mod_name|
        File.directory?(File.join(project_dir, "modules",  mod_name))
    end
end

def write_puppetfile(content)
    File.open("#{project_dir}/Puppetfile", "w") do |puppetfile|
        puppetfile.puts content
    end
end


module Ports
    def self.next!
        @port ||= 9000
        @port += 1
    end
end
