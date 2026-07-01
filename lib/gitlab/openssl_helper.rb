require_relative 'ohai_helper'
require_relative 'linker_libs_helper'

class OpenSSLHelper
  class << self
    def linker_libs
      @linker_libs ||= LinkerLibsHelper.new(
        base_libs: %w[libssl libcrypto],
        pkg_config_files: OhaiHelper.amazon_linux_2? ? { "openssl11.pc" => nil, "libssl11.pc" => nil, "libcrypto11.pc" => nil } : { "openssl.pc" => nil, "libssl.pc" => nil, "libcrypto.pc" => nil },
        pkg_config_threshold: 3
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
      libssl_path = find_libs("libssl.so")['libssl.so']
      libcrypt_path = find_libs("libcrypto.so")['libcrypto.so']

      "-DUSE_HTTPS=OpenSSL -DOPENSSL_SSL_LIBRARY=#{libssl_path} -DOPENSSL_CRYPTO_LIBRARY=#{libcrypt_path}"
    end
  end
end
