require 'cgi'

require_relative '../ohai_helper'
require_relative '../util'
require_relative '../version'

module Build
  # The glaz-ffi bundle: GLAZ's policy engine as a per-architecture static
  # library. https://gitlab.com/gitlab-org/auth/glaz/-/blob/main/docs/ffi.md
  class GlazFFI
    # Overridable so a release mirror can serve the bundle without a code change.
    API_V4_URL = Gitlab::Util.get_env('GLAZ_FFI_API_V4_URL') || 'https://gitlab.com/api/v4'
    REGISTRY_PROJECT = CGI.escape(Gitlab::Util.get_env('GLAZ_FFI_REGISTRY_PROJECT') || 'gitlab-org/auth/glaz')

    class << self
      def version
        Gitlab::Version.new('glaz-ffi')
      end

      def triple
        "#{OhaiHelper.arch}-unknown-linux-gnu"
      end

      def bundle_dir_name
        "glaz-ffi-#{version.upstream_version}-#{triple}"
      end

      def source_args
        sha256 = version.source_sha256.fetch(OhaiHelper.arch) do
          raise "glaz-ffi #{version.upstream_version} publishes no #{triple} bundle; " \
                "see the sha256 map in #{Gitlab::Version::SOFTWARE_VERSIONS_FILENAME}"
        end

        {
          url: "#{API_V4_URL}/projects/#{REGISTRY_PROJECT}/packages/generic/glaz-ffi/#{version.upstream_version}/#{bundle_dir_name}.tar.gz",
          sha256: sha256,
        }
      end

      # Where the bundle's link inputs are staged for gitlab-kas. The path must
      # live below the install dir: the build cache restores the install dir
      # but not the extracted source tree, so only this location survives a
      # cache-restored glaz-ffi paired with a gitlab-kas rebuild. The package
      # excludes it (config/projects/gitlab.rb).
      def dir(install_dir)
        File.join(install_dir, 'embedded', 'glaz-ffi')
      end
    end
  end
end
