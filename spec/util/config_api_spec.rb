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

require 'spec_helper'

module PuppetLibrary::Util
    describe ConfigApi do
        describe "#for" do
            it "creates a config API" do
                api = ConfigApi.for(self.class) do
                    required :name, "String"
                end

                config = api.configure do
                    name "Dave"
                end

                expect(config.get_name).to eq "Dave"
            end

            it "sees the block's scope" do
                api = ConfigApi.for(self.class) do
                    required :name, "String"
                end

                daves_name = "Dave"
                config = api.configure do
                    name daves_name
                end

                expect(config.get_name).to eq "Dave"
            end

            context "when a required parameter is missing" do
                it "throws an exception" do
                    api = ConfigApi.for(self.class) do
                        required :name, "String"
                    end

                    expect {
                        api.configure do
                        end
                    }.to raise_error /name/
                end
            end

            context "when a parameter isn't valid, according to its validator" do
                it "throws an exception" do
                    api = ConfigApi.for(self.class) do
                        required :name, "String" do |value|
                            raise "Invalid!"
                        end
                    end

                    expect {
                        api.configure do
                            name "Dave"
                        end
                    }.to raise_error /Invalid!/
                end
            end
        end
    end
end
