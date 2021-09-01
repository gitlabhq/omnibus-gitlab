require_relative 'linker_helper'

class OpenSSLHelper
  @base_libs = %w[libssl libcrypto]
  @deps = []
  @cursor = 2

  class << self
    def allowed_libs
      @base_libs.each do |lib|
        find_deps(lib)
      end

      @deps.map { |dep| File.basename(dep).split(".so").first }.uniq
    end

    def find_libs(name)
      LinkerHelper.ldconfig.select { |lib| lib.start_with?(name) }
    end

    def append_deps(path)
      @cursor += 1

      return if path.start_with?("/opt/gitlab") || !path.start_with?("/")

      puts "\tFinding dependencies of #{path}"
      items = LinkerHelper.ldd(path).values.reject { |lib| lib == "statically" }

      @deps.concat(items).uniq!
    end

    def find_deps(name)
      puts "Libraries starting with '#{name}' and their dependencies"
      @deps << name
      libs = find_libs(name)

      libs.each do |lib, path|
        append_deps(path)
      end

      loop do
        break if @cursor >= @deps.length

        append_deps(@deps[@cursor])
      end
    end
  end
end
