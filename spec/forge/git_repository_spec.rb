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
    describe GitRepository do
        @@repo_dir = Tempdir.new("git-repo")
        @@versions = [ "0.1.0", "0.9.0", "1.0.0-rc1", "1.0.0", "1.0.1" ]
        @@tags = @@versions.map {|version| "v#{version}"} + [ "xxx" ]

        before :all do
            def git(command)
                git_command = "git --git-dir=#{@@repo_dir.path}/.git --work-tree=#{@@repo_dir.path} #{command}"
                pid, stdin, stdout, stderr = Open4.popen4(git_command)
                ignored, status = Process::waitpid2 pid
                unless status.success?
                    raise "Error running Git command: #{git_command}\n#{stdout.read}\n#{stderr.read}"
                end
            end

            git "init"
            git "config user.name tester"
            git "config user.email tester@example.com"
            @@versions.zip(@@tags).each do |(version, tag)|
                # Add some changes for the version
                change_file_path = File.join(@@repo_dir.path, "changes.txt")
                File.open(change_file_path, "a") do |change_file|
                    change_file.puts "Version #{version}"
                end

                modulefile_path = File.join(@@repo_dir.path, "Modulefile")
                metadata_file_path = File.join(@@repo_dir.path, "metadata.json")

                # Update the module file
                File.open(modulefile_path, "w") do |modulefile|
                    modulefile.write <<-MODULEFILE
                    name 'puppetlabs-apache'
                    version '#{version}'
                    author 'puppetlabs'
                    MODULEFILE
                end

                # A dodgy early version with no modulefile
                if version == "0.1.0"
                    File.delete modulefile_path
                end

                # A later version with metadata.json instead of modulefile
                if version == "1.0.1"
                    File.delete modulefile_path
                    File.open(metadata_file_path, "w") do |metadata_file|
                        metadata = {
                            "name" => "puppetlabs-apache",
                            "version" => "1.0.1",
                            "author" => "puppetlabs"
                        }

                        metadata_file.write metadata.to_json
                    end
                end

                git "add ."
                git "commit --message='Version #{version}'"
                git "tag #{tag}"
            end
        end

        let :forge do
            cache_dir = Tempdir.new("git-repo-cache")
            git = PuppetLibrary::Util::Git.new(@@repo_dir.path, cache_dir)
            GitRepository.new(git, /[0-9.]+/)
        end

        describe "#configure" do
            it "exposes a configuration API" do
                forge = GitRepository.configure do
                    source @@repo_dir.path
                    include_tags /v123/
                end
                expect(forge.instance_eval "@version_tag_regex").to eq /v123/
            end
        end

        describe "#prime" do
            it "creates the repo cache" do
                git = double('git')
                forge = GitRepository.new(git, //)

                expect(git).to receive(:update_cache!)

                forge.prime
            end
        end

        describe "#clear_cache" do
            it "deletes the repo cache" do
                git = double('git')
                forge = GitRepository.new(git, //)

                expect(git).to receive(:clear_cache!)

                forge.clear_cache
            end
        end

        describe "#get_module" do
            context "when the requested author is different from the configured author" do
                it "returns nil" do
                    buffer = forge.get_module("dodgybrothers", "apache", "1.0.0")
                    expect(buffer).to be_nil
                end
            end

            context "when the requested module name is different from the configured name" do
                it "returns nil" do
                    buffer = forge.get_module("puppetlabs", "stdlib", "1.0.0")
                    expect(buffer).to be_nil
                end
            end

            context "when the tag for the requested version doesn't exist" do
                it "returns nil" do
                    buffer = forge.get_module("puppetlabs", "apache", "9.9.9")
                    expect(buffer).to be_nil
                end
            end

            context "when the module is requested" do
                it "returns an archive of the module" do
                    buffer = forge.get_module("puppetlabs", "apache", "1.0.0")
                    expect(buffer).to be_tgz_with "puppetlabs-apache-1.0.0/Modulefile", /version '1.0.0'/
                end
                it "generates the metadata file and includes it in the archive" do
                    buffer = forge.get_module("puppetlabs", "apache", "1.0.0")
                    expect(buffer).to be_tgz_with "puppetlabs-apache-1.0.0/metadata.json", /"version":"1.0.0"/
                end
            end
        end

        describe "#get_metadata" do
            context "when the requested author is different from the configured author" do
                it "returns nil" do
                    metadata = forge.get_metadata("dodgybrothers", "apache")
                    expect(metadata).to be_empty
                end
            end

            context "when the requested module name is different from the configured name" do
                it "returns an empty array" do
                    metadata = forge.get_metadata("puppetlabs", "stdlib")
                    expect(metadata).to be_empty
                end
            end

            context "when the module is requested" do
                context "when there is a metadata file, but no modulefile" do
                    it "returns the metadata for each version" do
                        metadata = forge.get_metadata("puppetlabs", "apache")
                        expect(metadata.size).to eq(4)
                        expect(metadata.last["name"]).to eq "puppetlabs-apache"
                        expect(metadata.last["version"]).to eq "1.0.1"
                    end
                end

                context "when there is a modulefile" do
                    it "generates the metadata for the each version" do
                        metadata = forge.get_metadata("puppetlabs", "apache")
                        expect(metadata.size).to eq(4)
                        expect(metadata.first["name"]).to eq "puppetlabs-apache"
                        expect(metadata.first["version"]).to eq "0.9.0"
                    end
                end
            end
        end

        describe "#get_all_metadata" do
            it "generates the metadata for the each version" do
                metadata = forge.get_all_metadata
                expect(metadata.size).to eq(4)
                expect(metadata.first["name"]).to eq "puppetlabs-apache"
                expect(metadata.first["version"]).to eq "0.9.0"
            end

            it "doesn't include versions with no metadata file and no Modulefile" do
                metadata = forge.get_all_metadata
                dodgy_version = metadata.find {|m| m["version"] == "0.1.0" }
                expect(dodgy_version).to be_nil
            end
        end
    end
end
