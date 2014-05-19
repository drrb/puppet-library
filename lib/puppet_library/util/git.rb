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

require 'fileutils'
require 'monitor'
require 'time'
require 'open4'
require 'puppet_library/util/logging'
require 'puppet_library/util/temp_dir'

module PuppetLibrary::Util
    class Git
        include Logging

        DEFAULT_CACHE_TTL_SECONDS = 60
        def initialize(source, cache_dir, cache_ttl_seconds = DEFAULT_CACHE_TTL_SECONDS)
            @source = source
            @cache_dir = cache_dir
            @cache_ttl_seconds = cache_ttl_seconds
            @git_dir = File.join(@cache_dir.path, ".git")
            @mutex = Monitor.new
        end

        def tags
            update_cache!
            git("tag").split
        end

        def with_tag(tag)
            update_cache!
            PuppetLibrary::Util::TempDir.use "git" do |path|
                git "checkout #{tag}", path
                yield(path)
            end
        end

        def read_file(path, tag)
            update_cache!
            git "show refs/tags/#{tag}:#{path}"
        end

        def file_exists?(path, tag)
            read_file(path, tag)
            true
        rescue GitCommandError
            false
        end

        def clear_cache!
            @mutex.synchronize do
                info "Clearing cache for Git repository #{@source} from #{@git_dir}"
                FileUtils.rm_rf @cache_dir.path
            end
        end

        def update_cache!
            create_cache unless cache_exists?
            update_cache if cache_stale?
        end

        private
        def create_cache
            @mutex.synchronize do
                info "Cloning Git repository from #{@source} to #{@git_dir}"
                git "clone --mirror #{@source} #{@git_dir}"
                FileUtils.touch fetch_file
            end
        end

        def update_cache
            @mutex.synchronize do
                git "fetch origin --tags --update-head-ok"
            end
        end

        def cache_exists?
            File.directory? @git_dir
        end

        def cache_stale?
            Time.now - last_fetch > @cache_ttl_seconds
        end

        def last_fetch
            if File.exist? fetch_file
                File.stat(fetch_file).mtime
            else
                Time.at(0)
            end
        end

        def fetch_file
            File.join(@git_dir, "FETCH_HEAD")
        end

        def git(command, work_tree = nil)
            work_tree = @cache_dir.path unless work_tree
            run "git --git-dir=#{@git_dir} --work-tree=#{work_tree} #{command}"
        end

        def run(command)
            debug command
            pid, stdin, stdout, stderr = Open4.popen4(command)
            ignored, status = Process::waitpid2 pid
            unless status.success?
                raise GitCommandError, "Error running Git command: #{command}\n#{stdout.read}\n#{stderr.read}"
            end
            stdout.read
        ensure
            stdin.close
            stdout.close
            stderr.close
        end

        class GitCommandError < StandardError
        end
    end
end
