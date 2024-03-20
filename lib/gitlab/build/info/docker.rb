require_relative '../../util'
require_relative '../check'
require_relative '../info/ci'
require_relative '../info/package'

module Build
  class Info
    class Docker
      class << self
        def tag
          Gitlab::Util.get_env('IMAGE_TAG') || Build::Info::Package.release_version.tr('+', '-')
        end

        def release_file_contents
          repo = Gitlab::Util.get_env('PACKAGECLOUD_REPO') # Target repository
          download_urls = {}.tap do |urls|
            urls[:amd64] = Build::Info::CI.package_download_url
            urls[:arm64] = Build::Info::CI.package_download_url(arch: 'arm64')
          end

          raise "Unable to identify package download URLs." if download_urls.empty?

          contents = []
          contents << "PACKAGECLOUD_REPO=#{repo.chomp}\n" if repo && !repo.empty?
          contents << "RELEASE_PACKAGE=#{Build::Info::Package.name}\n"
          contents << "RELEASE_VERSION=#{Build::Info::Package.release_version}\n"
          contents << "DOWNLOAD_URL_amd64=#{download_urls[:amd64]}\n"
          contents << "DOWNLOAD_URL_arm64=#{download_urls[:arm64]}\n"
          contents << "CI_JOB_TOKEN=#{Build::Info::CI.job_token}\n"
          contents.join
        end
      end
    end
  end
end
