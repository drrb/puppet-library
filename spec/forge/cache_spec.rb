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

require 'spec_helper'

module PuppetLibrary::Forge
    describe Cache do
        let(:cache_dir) { Tempdir.create("module-cache") }
        let(:http_client) { double(PuppetLibrary::Http::HttpClient) }
        let(:forge) { Cache.new("forge.example.com", cache_dir, http_client) }

        it "is a proxy" do
            expect(forge).to be_a Proxy
        end

        describe "#get_module_buffer" do
            before do
                allow(http_client).to receive(:get).
                    with("http://forge.example.com/api/v1/releases.json?module=puppetlabs/apache").
                    and_return('{"puppetlabs/apache":[{"version":"1.0.0","file":"/puppetlabs/apache.tgz","dependencies":[["puppetlabs/concat",">= 1.0.0"],["puppetlabs/stdlib","~> 2.0.0"]]},{"version":"2.0.0","dependencies":[]}]}')
            end

            context "the first time it's called" do
                it "downloads the module to disk and serves it" do
                    file_buffer = StringIO.new("apache module")
                    expect(http_client).to receive(:download).
                        with("http://forge.example.com/puppetlabs/apache.tgz").
                        and_return(file_buffer)

                    buffer = forge.get_module_buffer("puppetlabs", "apache", "1.0.0")

                    downloaded_file = File.join(cache_dir, "puppetlabs-apache-1.0.0.tar.gz")
                    expect(File.read downloaded_file).to eq "apache module"
                    expect(buffer.read).to eq "apache module"
                end
            end

            context "the second time it's called" do
                it "serves the cached module from the disk" do
                    cached_module = File.join(cache_dir, "puppetlabs-apache-1.0.0.tar.gz")
                    File.open(cached_module, "w") do |file|
                        file.write "apache module"
                    end
                    expect(http_client).not_to receive(:download)

                    buffer = forge.get_module_buffer("puppetlabs", "apache", "1.0.0")

                    expect(buffer.read).to eq "apache module"
                end
            end
        end
    end
end
