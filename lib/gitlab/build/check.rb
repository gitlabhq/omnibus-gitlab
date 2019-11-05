require_relative "info.rb"
require_relative "../util.rb"

module Build
  class Check
    AUTO_DEPLOY_TAG_REGEX = /^\d+\.\d+\.\d+\+[^ ]{7,}\.[^ ]{7,}$/.freeze
    class << self
      def is_ee?
        Gitlab::Util.get_env('ee') == 'true' || \
          Gitlab::Util.get_env('GITLAB_VERSION')&.end_with?('-ee') || \
          File.read('VERSION').strip.end_with?('-ee') || \
          is_auto_deploy?
      end

      def match_tag?(tag)
        system(*%W[git describe --exact-match --match #{tag}])
      end

      def is_auto_deploy?
        is_auto_deploy_tag? || is_auto_deploy_branch?
      end

      def is_auto_deploy_tag?
        AUTO_DEPLOY_TAG_REGEX.match?(Build::Info.current_git_tag)
      end

      def is_auto_deploy_branch?
        Gitlab::Util.get_env('CI_COMMIT_REF_NAME')&.include?('-auto-deploy-')
      end

      def is_patch_release?
        # Major and minor releases have patch component as zero
        Info.semver_version.split(".")[-1] != "0"
      end

      def is_rc_tag?
        Build::Info.current_git_tag.include?("+rc")
      end

      def ci_commit_tag?
        Gitlab::Util.get_env('CI_COMMIT_TAG')
      end

      def is_latest_stable_tag?
        match_tag?(Info.latest_stable_tag)
      end

      def is_latest_tag?
        match_tag?(Info.latest_tag)
      end

      def is_nightly?
        Gitlab::Util.get_env('NIGHTLY') == 'true'
      end

      def no_changes?
        system(*%w[git diff --quiet])
      end

      def on_tag?
        system(*%w[git describe --exact-match])
      end
    end
  end
end
