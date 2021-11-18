require_relative 'linker_helper'

class OpenSSLHelper
  @base_libs = %w[libssl libcrypto]
  @pkg_config_files = { "libssl.pc" => nil, "libcrypto.pc" => nil }
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

    def pkg_config_files?
      @pkg_config_files.values.compact.length >= 2
    end

    def system_pkg_config_dirs
      @system_pkg_config_dirs ||= IO.popen(%w[pkg-config --variable pc_path pkg-config], &:read)&.split(":")&.map(&:strip)
    end

    def pkg_config_files
      return @pkg_config_files if pkg_config_files?

      system_pkg_config_dirs.each do |pkg_config_dir|
        break if pkg_config_files?

        @pkg_config_files.each do |filename, filepath|
          next unless filepath.nil?

          file_path = File.expand_path(filename, pkg_config_dir)
          @pkg_config_files[filename] = file_path if File.exist? file_path
        end
      end

      @pkg_config_files
    end

    def pkg_config_dirs
      @pkg_config_dirs ||= pkg_config_files.values.map { |f| File.dirname(f) }.uniq.join(":")
    end

    def cmake_flags
      libssl_path = find_libs("libssl.so")['libssl.so']
      libcrypt_path = find_libs("libcrypto.so")['libcrypto.so']

      "-DUSE_HTTPS=OpenSSL -DOPENSSL_SSL_LIBRARY=#{libssl_path} -DOPENSSL_CRYPTO_LIBRARY=#{libcrypt_path}"
    end
  end
end
