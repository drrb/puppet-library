require 'spec_helper'
require 'zlib'
require 'rubygems/package'

module PuppetLibrary
    describe ModuleRepo do

        let(:module_dir) { "/tmp/#{$$}" }
        let(:module_repo) { ModuleRepo.new(module_dir) }

        before do
            FileUtils.mkdir_p module_dir
        end

        after do
            FileUtils.rm_rf module_dir
        end

        def add_module(author, name, version)
            full_name = "#{author}-#{name}"
            fqn = "#{full_name}-#{version}"
            module_file = File.join(module_dir, "#{fqn}.tar.gz")

            write_tar_gzip(module_file) do |archive|
                archive.add_file("#{fqn}/metadata.json", 0644) do |file|
                    content = {
                        "name" => full_name,
                        "version" => version
                    }
                    file.write content.to_json
                end
            end
        end

        describe "#get_metadata" do
            context "when the module directory is empty" do
                it "returns an empty array" do
                    metadata_list = module_repo.get_metadata("puppetlabs", "apache")
                    expect(metadata_list).to be_empty
                end
            end

            context "when the module directory contains the requested module" do
                before do
                    add_module("puppetlabs", "apache", "1.0.0")
                    add_module("puppetlabs", "apache", "1.1.0")
                end

                it "returns an array containing the module's versions' metadata" do
                    metadata_list = module_repo.get_metadata("puppetlabs", "apache")
                    expect(metadata_list.size).to eq 2
                    expect(metadata_list[0]).to eq({ "name" => "puppetlabs-apache", "version" => "1.0.0" })
                    expect(metadata_list[1]).to eq({ "name" => "puppetlabs-apache", "version" => "1.1.0" })
                end
            end
        end
    end
end
