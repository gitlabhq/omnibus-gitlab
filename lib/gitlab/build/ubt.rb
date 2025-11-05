module Build
  class UBT
    UBT_PROJECT = CGI.escape(Gitlab::Util.get_env('UBT_REGISTRY_PROJECT') || "gitlab-org/distribution/build-architecture/framework/foundation/gitlab-toolchain")
    class << self
      def source_args(name, version, sha_checksum, arch = "x86_64")
        ubt_bundle_url = "#{Build::Info::CI.api_v4_url}/projects/#{UBT_PROJECT}/packages/generic/#{name}/#{version}/#{name}-#{version}-#{arch}.tgz"
        # When private_token is nil or empty net_fetcher should just ignore it
        {
          url: ubt_bundle_url,
          sha256: sha_checksum,
          private_token: Build::Info::Secrets.ubt_fetch_token,
          job_token: Build::Info::Secrets.ci_job_token,
          extract: true
        }
      end

      def install
        proc {
          mkdir install_dir.to_s
          copy "#{project_dir}#{install_dir}/embedded", install_dir.to_s, preserve: true
        }
      end
    end
  end
end
