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
            Modulefile.new.tap do |modulefile|
                modulefile.instance_eval(File.read(modulefile_path))
            end
        end

        %w[name version author description].each do |property|
            class_eval <<-EOF
                def #{property}(value)
                    @#{property} = value
                end

                def get_#{property}
                    @#{property}
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
            puts "Method called: #{name}(#{args.join", "})"
        end

        def to_metadata
            {
                "name" => get_name,
                "version" => get_version,
                "author" => get_author,
                "description" => get_description,
                "dependencies" => get_dependencies
            }
        end
    end
end
