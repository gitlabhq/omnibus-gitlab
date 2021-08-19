require_relative 'linker_helper'

class OpenSSLHelper
  @deps = %w[libssl libcrypto]
  @index = 2

  class << self
    def allowed_libs
      find_deps("libssl")
      find_deps("libcrypto")

      @deps.map { |dep| File.basename(dep).split(".so").first }.uniq
    end

    def find_libs(name)
      LinkerHelper.ldconfig.select { |lib| lib.start_with?(name) }
    end

    def append_deps(path)
      @index += 1

      return if path.start_with?("/opt/gitlab") || !path.start_with?("/")

      puts "\tFinding dependencies of #{path}"
      items = LinkerHelper.ldd(path).values.reject { |lib| lib == "statically" }

      @deps.concat(items).uniq!
    end

    def find_deps(name)
      puts "Libraries starting with '#{name}' and their dependencies"
      libs = find_libs(name)

      libs.each do |lib, path|
        append_deps(path)
      end

      loop do
        break if @index >= @deps.length

        append_deps(@deps[@index])
      end
    end
  end
end
