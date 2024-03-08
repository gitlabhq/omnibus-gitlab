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

          download_url = if /dev.gitlab.org/.match?(Build::Info::CI.api_v4_url) || Build::Check.is_nightly?
                           Build::Info::CI.package_download_url
                         else
                           Build::Info::CI.triggered_package_download_url
                         end

          raise "Unable to identify package download URL." unless download_url

          contents = []
          contents << "PACKAGECLOUD_REPO=#{repo.chomp}\n" if repo && !repo.empty?
          contents << "RELEASE_PACKAGE=#{Build::Info::Package.name}\n"
          contents << "RELEASE_VERSION=#{Build::Info::Package.release_version}\n"
          contents << "DOWNLOAD_URL=#{download_url}\n"
          contents << "CI_JOB_TOKEN=#{Build::Info::CI.job_token}\n"
          contents.join
        end
      end
    end
  end
end
