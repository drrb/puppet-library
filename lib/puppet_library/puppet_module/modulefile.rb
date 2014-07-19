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

module PuppetLibrary::PuppetModule
    class Modulefile
        def self.read(modulefile_path)
            parse(File.open(modulefile_path, "r:UTF-8").read)
        end

        def self.parse(modulefile_source)
            Modulefile.new.tap do |modulefile|
                modulefile.instance_eval(modulefile_source)
            end
        end

        %w[name version author source summary description project_page license].each do |property|
            class_eval <<-EOF
                def #{property}(value)
                    @#{property} = value
                end

                def get_#{property}
                    @#{property} || ""
                end
            EOF
        end

        def dependency(name, spec)
            get_dependencies.push("name" => name, "version_requirement" => spec)
        end

        def get_dependencies
            @dependencies ||= []
        end

        def get_simple_name
            @name.split("-").last
        end

        def method_missing(name, *args, &block)
            Modulefile.log "Unsupported config parsed from Modulefile: #{name}(#{args.join", "})"
        end

        def to_metadata
            {
                "name" => get_name,
                "version" => get_version,
                "source" => get_source,
                "author" => get_author,
                "license" => get_license,
                "summary" => get_summary,
                "description" => get_description,
                "project_page" => get_project_page,
                "dependencies" => get_dependencies
            }
        end

        private
        def self.log(message)
            puts message
        end
    end
end
