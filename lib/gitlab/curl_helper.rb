require_relative 'linker_libs_helper'

class CurlHelper
  # We accept 5 as the minimum number of required pkg-config files for these reasons:
  #
  # - AlmaLinux and Ubuntu provide 6 pkg-config files:
  #     libbrotlicommon.pc, libbrotlidec.pc, libcurl.pc, libidn2.pc,
  #     libnghttp2.pc, libpsl.pc, libssh2.pc
  #
  # - AmazonLinux 2 has libssh2 installed but libssh2-devel conflicts with
  #     openssl11-devel, so libssh2.pc is not available and only 5 pkg-config
  #     files are present on that platform.
  #
  # - AmazonLinux 2023 ships libssh.pc as a transitive dependency of
  #     libcurl.pc; we install libssh-devel for the .pc file. It also
  #     requires libngtcp2.pc, libngtcp2_crypto_ossl.pc, and libnghttp3.pc
  #     which are not required on other distros.
  PKG_CONFIG_THRESHOLD = 5

  class << self
    def linker_libs
      @linker_libs ||= LinkerLibsHelper.new(
        base_libs: %w[libcurl],
        pkg_config_files: {
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
        },
        pkg_config_threshold: PKG_CONFIG_THRESHOLD
      )
    end

    def allowed_libs
      linker_libs.allowed_libs
    end

    def find_libs(name)
      linker_libs.find_libs(name)
    end

    def pkg_config_files
      linker_libs.pkg_config_files
    end

    def pkg_config_dirs
      linker_libs.pkg_config_dirs
    end

    def cmake_flags
      libcurl_path = find_libs("libcurl.so")['libcurl.so']

      "-DUSE_CURL=ON -DCURL_LIBRARY=#{libcurl_path}"
    end
  end
end
