require 'zlib'
require 'rubygems/package'

module ModuleSpecHelper
    def write_tar_gzip(file_name)
        tar = StringIO.new

        Gem::Package::TarWriter.new(tar) do |writer|
            yield(writer)
        end
        tar.seek(0)

        gz = Zlib::GzipWriter.new(File.new(file_name, 'wb'))
        gz.write(tar.read)
        tar.close
        gz.close
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
end
