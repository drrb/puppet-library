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

require 'json'
require 'redcarpet'
require 'puppet_library/forge/abstract'
require 'puppet_library/util/config_api'

module PuppetLibrary::Forge
  
  # A forge that serves modules in unpacked format from a directory on disk.
  #
  # <b>Note:</b>
  # * The modules must be in unpacked format
  # * The modules (directories) must be named in the format <tt>modulename</tt>
  # * The modules must contain a +metadata.json+ file
  #
  # <b>Usage:</b>
  #
  #    forge = PuppetLibrary::Forge::SourceDirectory.configure do
  #        # The path to serve the modules from
  #        path "/var/modules/cache"
  #    end
  class SourceDirectory < PuppetLibrary::Forge::Abstract
    def self.configure(&block)
      config_api = PuppetLibrary::Util::ConfigApi.for(SourceDirectory) do
                      required :path, "path to the modules' source" do |path|
                          Dir.new(File.expand_path(path))
                      end
                  end
                  config = config_api.configure(&block)
                  Source.new(config.get_path)
    end

    # * <tt>:module_dir</tt> - The directory containing the packaged modules.
    def initialize(module_dir)
      super(self)
      @module_dir = module_dir
    end

    def get_module(name)
      file_name = "#{name}"
      path = File.join(@module_dir.path, file_name)
      if File.exist? path
        File.open(path, 'r')
      else
        nil
      end
    end

    def get_all_metadata
      get_metadata("*")
    end

    def get_metadata(module_name)
      archives = Dir["#{@module_dir.path}/#{module_name}"]
      archives.map {|path| read_metadata(path) }.compact
    end

    private

    def read_metadata(archive_path)
      metadata_file = File.open(File.join(@module_dir.path, "metadata.json"), "r").read

      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, extensions = {})
      readmeText = File.open("README.md", "r").read
      readmeHTML = markdown.render(readmeText)
      parsedJSON = JSON.parse(metadata_file)

      parsedJSON["documentation"] = readmeHTML
      parsedJSON

    rescue => error
      warn "Error reading from module archive #{archive_path}: #{error}"
      return nil
    end
  end
end

