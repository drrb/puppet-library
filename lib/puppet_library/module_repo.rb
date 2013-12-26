module PuppetLibrary
    class ModuleRepo
        def initialize(module_dir)
            @module_dir = module_dir
        end

        def get_metadata(author, module_name)
            Dir["#{@module_dir}/#{author}-#{module_name}*"].map do |module_path|
                tar = Gem::Package::TarReader.new(Zlib::GzipReader.open(module_path))
                tar.rewind
                metadata_source = tar.find {|e| e.full_name =~ /[^\/]+\/metadata\.json/}.read
                JSON.parse(metadata_source)
            end
        end
    end
end
