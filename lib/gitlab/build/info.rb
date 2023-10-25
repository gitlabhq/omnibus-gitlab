require_relative 'info/git'
require_relative '../build_iteration'
require_relative "../util.rb"
require_relative './info/ci'
require_relative './info/package'
require_relative 'check'
require_relative 'image'

module Build
  class Info
    class << self
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
    end
  end
end
