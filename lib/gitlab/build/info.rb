require_relative 'info/git'
require_relative '../build_iteration'
require_relative "../util.rb"
require_relative './info/ci'
require_relative './info/package'
require_relative 'check'
require_relative 'image'

module Build
  class Info
    DEPLOYER_OS_MAPPING = {
      'AUTO_DEPLOY_ENVIRONMENT' => 'ubuntu-xenial',
      'PATCH_DEPLOY_ENVIRONMENT' => 'ubuntu-bionic',
      'RELEASE_DEPLOY_ENVIRONMENT' => 'ubuntu-focal',
    }.freeze

    class << self
      def docker_tag
        Gitlab::Util.get_env('IMAGE_TAG') || Build::Info::Package.release_version.tr('+', '-')
      end

      def qa_image
        Gitlab::Util.get_env('QA_IMAGE') || "#{Gitlab::Util.get_env('CI_REGISTRY')}/#{Build::Info::Components::GitLabRails.project_path}/#{Build::Info::Package.name}-qa:#{Build::Info::Components::GitLabRails.ref(prepend_version: false)}"
      end

      def gcp_release_bucket
        # All tagged builds are pushed to the release bucket
        # whereas regular branch builds use a separate one
        gcp_pkgs_release_bucket = Gitlab::Util.get_env('GITLAB_COM_PKGS_RELEASE_BUCKET') || 'gitlab-com-pkgs-release'
        gcp_pkgs_builds_bucket = Gitlab::Util.get_env('GITLAB_COM_PKGS_BUILDS_BUCKET') || 'gitlab-com-pkgs-builds'
        Check.on_tag? ? gcp_pkgs_release_bucket : gcp_pkgs_builds_bucket
      end

      def gcp_release_bucket_sa_file
        Gitlab::Util.get_env('GITLAB_COM_PKGS_SA_FILE')
      end

      def log_level
        if Gitlab::Util.get_env('BUILD_LOG_LEVEL') && !Gitlab::Util.get_env('BUILD_LOG_LEVEL').empty?
          Gitlab::Util.get_env('BUILD_LOG_LEVEL')
        else
          'info'
        end
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

      def image_reference
        "#{Build::GitlabImage.gitlab_registry_image_address}:#{Info.docker_tag}"
      end

      def deploy_env_key
        if Build::Check.is_auto_deploy_tag?
          'AUTO_DEPLOY_ENVIRONMENT'
        elsif Build::Check.is_rc_tag?
          'PATCH_DEPLOY_ENVIRONMENT'
        elsif Build::Check.is_latest_stable_tag?
          'RELEASE_DEPLOY_ENVIRONMENT'
        end
      end

      def deploy_env
        key = deploy_env_key

        return nil if key.nil?

        env = Gitlab::Util.get_env(key)

        abort "Unable to determine which environment to deploy too, #{key} is empty" unless env

        puts "Ready to send trigger for environment(s): #{env}"

        env
      end
    end
  end
end
