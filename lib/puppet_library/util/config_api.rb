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

require 'docile'

module PuppetLibrary::Util
    class ConfigApi
        def self.configure(owner, *fields, &block)
            class_name = "#{owner.name.split('::').last}Config"
            config_class = if PuppetLibrary.const_defined?(class_name.intern)
                               PuppetLibrary.const_get(class_name)
                           else
                               define_class(class_name, fields)
                           end
            Docile.dsl_eval(config_class.new, &block)
        end

        def self.define_class(class_name, fields)
            config_class = Class.new do
                fields.each do |field|
                    define_method(field.to_sym) do |new_value|
                        instance_variable_set "@#{field}", new_value
                    end
                    define_method("get_#{field}".to_sym) do
                        instance_variable_get "@#{field}"
                    end
                end
            end
            PuppetLibrary.const_set(class_name, config_class)
        end
    end
end
