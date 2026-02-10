require_relative 'linker_helper'
require_relative 'ohai_helper'

class CurlHelper
  @base_libs = %w[libcurl]
  @pkg_config_files = {
    "libbrotlicommon.pc" => nil,
    "libbrotlidec.pc" => nil,
    "libcurl.pc" => nil,
    "libidn2.pc" => nil,
    "libnghttp2.pc" => nil,
    "libpsl.pc" => nil,
    "libngtcp2.pc" => nil,
    "libngtcp2_crypto_ossl.pc" => nil,
    "libnghttp3.pc" => nil,
    "libssh2.pc" => nil,
    "libssh.pc" => nil
  }
  @deps = []

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
      return if path.start_with?("/opt/gitlab") || !path.start_with?("/")

      puts "\tFinding dependencies of #{path}"
      items = LinkerHelper.ldd(path).values.reject { |lib| lib == "statically" }

      @deps.concat(items).uniq!
    end

    def find_deps(name)
      puts "Libraries starting with '#{name}' and their dependencies"
      @deps << name
      start = @deps.length
      libs = find_libs(name)

      libs.each do |lib, path|
        append_deps(path)
      end

      cursor = start

      loop do
        break if cursor >= @deps.length

        append_deps(@deps[cursor])
        cursor += 1
      end
    end

    # We accept 5 as the minimum number of required pkg-config files for the following reasons:
    #
    # - AlmaLinux and Ubuntu provide 6 pkg-config files:
    #     libbrotlicommon.pc, libbrotlidec.pc, libcurl.pc, libidn2.pc,
    #     libnghttp2.pc, libpsl.pc, libssh2.pc
    #
    # - AmazonLinux 2 has libssh2 installed but libssh2-devel conflicts with
    #     openssl11-devel, so libssh2.pc is not available and only 5 pkg-config
    #     files are present on that platform.
    #
    # - AmazonLinux 2023 links to libssh.pc only when linking to libcurl.pc
    #     (we install libssh-devel which includes libssh.pc). It also requires
    #     libngtcp2.pc, libngtcp2_crypto_ossl.pc, and libnghttp3.pc which are
    #     not required on other distros.
    def pkg_config_files?
      @pkg_config_files.values.compact.length >= 5
    end

    def system_pkg_config_dirs
      @system_pkg_config_dirs ||= IO.popen(%w[pkg-config --variable pc_path pkg-config], &:read)&.split(":")&.map(&:strip)
    end

    def pkg_config_files
      return @pkg_config_files.compact if pkg_config_files?

      system_pkg_config_dirs.each do |pkg_config_dir|
        break if pkg_config_files?

        @pkg_config_files.each do |filename, filepath|
          next unless filepath.nil?

          file_path = File.expand_path(filename, pkg_config_dir)
          @pkg_config_files[filename] = file_path if File.exist? file_path
        end
      end

      @pkg_config_files.compact
    end

    def pkg_config_dirs
      @pkg_config_dirs ||= pkg_config_files.values.compact.map { |f| File.dirname(f) }.uniq.join(":")
    end

    def cmake_flags
      libcurl_path = find_libs("libcurl.so")['libcurl.so']

      "-DUSE_CURL=ON -DCURL_LIBRARY=#{libcurl_path}"
    end
  end
end
