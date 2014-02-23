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

require 'puppet_library/util/temp_dir'

module PuppetLibrary::Util
    class Git
        def initialize(path)
            @path = path
        end

        def tags
            git("tag").split
        end

        def on_tag(tag)
            PuppetLibrary::Util::TempDir.use "git" do |path|
                git "checkout #{tag}", path
                yield
            end
        end

        def read_file(path, tag = nil)
            if tag.nil?
                File.read(File.join(@path, path))
            else
                git "show refs/tags/#{tag}:#{path}"
            end
        end

        def git(command, work_tree = nil)
            work_tree = @path unless work_tree
            Open3.popen3("git --git-dir=#{@path}/.git --work-tree=#{work_tree} #{command}") do |stdin, stdout, stderr, thread|
                stdout.read
            end
        end
    end
end
