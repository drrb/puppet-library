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
        def self.for(owner, &block)
            Docile.dsl_eval(ConfigApi.new(owner), &block)
        end

        def initialize(owner)
            @owner = owner
            @params = []
        end

        def configure(&block)
            config_api = config_class.new
            Docile.dsl_eval(config_api, &block)
            config_api.validate!
        end

        def config_class
            class_name = "#{@owner.to_s.split('::').last}Config"
            if PuppetLibrary.const_defined?(class_name.intern)
                PuppetLibrary.const_get(class_name)
            else
                define_config_class(class_name)
            end
        end

        def define_config_class(class_name)
            params = @params
            config_class = Class.new do
                define_method(:validate!) do
                    params.select(&:required?).each do |param|
                        if send("get_#{param.name}").nil?
                            raise "Config parameter '#{param.name}' is required (expected #{param.description}), but wasn't specified"
                        end
                    end
                    self
                end
                params.each do |param|
                    define_method(param.name.to_sym) do |new_value|
                        begin
                            param.validate! new_value
                            instance_variable_set "@#{param.name}", new_value
                        rescue => validation_error
                            raise "Invalid value for config parameter '#{param.name}': #{validation_error.message} (was expecting #{param.description})"
                        end
                    end

                    define_method("get_#{param.name}".to_sym) do
                        instance_variable_get "@#{param.name}"
                    end
                end
            end
            PuppetLibrary.const_set(class_name, config_class)
        end

        def required(name, description, &validate)
            param(name, description, true, validate)
        end

        def param(name, description, required, validate)
            @params << Param.new(name, description, required, validate)
        end

        class Param
            attr_reader :name, :description

            def initialize(name, description, required, validate)
                @name, @description, @required, @validate = name, description, required, validate
            end

            def required?
                @required
            end

            def validate!(value)
                @validate.nil? || @validate.call(value)
            end
        end
    end
end
