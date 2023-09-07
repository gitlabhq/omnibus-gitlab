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

      def gitlab_version
        # Get the branch/version/commit of GitLab CE/EE repo against which package
        # is built. If GITLAB_VERSION variable is specified, as in triggered builds,
        # we use that. Else, we use the value in VERSION file.

        if Gitlab::Util.get_env('GITLAB_VERSION').nil? || Gitlab::Util.get_env('GITLAB_VERSION').empty?
          File.read('VERSION').strip
        else
          Gitlab::Util.get_env('GITLAB_VERSION')
        end
      end

      def gitlab_version_slug
        gitlab_version.downcase
          .gsub(/[^a-z0-9]/, '-')[0..62]
          .gsub(/(\A-+|-+\z)/, '')
      end

      def gitlab_rails_ref(prepend_version: true)
        # Returns the immutable git ref of GitLab rails being used.
        #
        # 1. In feature branch pipelines, generate-facts job will create
        #    version fact files which will contain the commit SHA of GitLab
        #    rails. This will be used by `Gitlab::Version` class and will be
        #    presented as version of `gitlab-rails` software component.
        # 2. In stable branch and tag pipelines, these version fact files will
        #    not be created. However, in such cases, VERSION file will be
        #    anyway pointing to immutable references (git tags), and hence we
        #    can directly use it.
        Gitlab::Version.new('gitlab-rails').print(prepend_version)
      end

      def gitlab_rails_project_path
        if Gitlab::Util.get_env('CI_SERVER_HOST') == 'dev.gitlab.org'
          Build::Info::Package.name == "gitlab-ee" ? 'gitlab/gitlab-ee' : 'gitlab/gitlabhq'
        else
          namespace = Gitlab::Version.security_channel? ? "gitlab-org/security" : "gitlab-org"
          project = Build::Info::Package.name == "gitlab-ee" ? 'gitlab' : 'gitlab-foss'

          "#{namespace}/#{project}"
        end
      end

      def gitlab_rails_repo
        gitlab_rails =
          if Build::Info::Package.name == "gitlab-ce"
            "gitlab-rails"
          else
            "gitlab-rails-ee"
          end

        Gitlab::Version.new(gitlab_rails).remote
      end

      def qa_image
        Gitlab::Util.get_env('QA_IMAGE') || "#{Gitlab::Util.get_env('CI_REGISTRY')}/#{gitlab_rails_project_path}/#{Build::Info::Package.name}-qa:#{gitlab_rails_ref(prepend_version: false)}"
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

        download_url = if /dev.gitlab.org/.match?(Build::Info::CI.api_v4_url)
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
