require_relative '../util'
require_relative 'info/git'
require_relative 'info/package'

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

      def is_jh?
        Gitlab::Util.get_env('jh') == 'true' || \
          Gitlab::Util.get_env('GITLAB_VERSION')&.end_with?('-jh') || \
          File.read('VERSION').strip.end_with?('-jh')
      end

      def include_ee?
        is_ee? || is_jh?
      end

      def boringcrypto_supported?
        system({ 'GOEXPERIMENT' => 'boringcrypto' }, *%w(go version))
      end

      def fips?
        # TODO: Add code to automatically set to true on FIPS supported OSs
        false
      end

      def use_system_ssl?
        # Once we implement the `fips?` TODO, we can get rid of this variable and
        # gate on `fips?` alone.
        Gitlab::Util.get_env('USE_SYSTEM_SSL') == 'true' || fips?
      end

      def use_system_libgcrypt?
        # Once we implement the `fips?` TODO, we can get rid of this variable and
        # gate on `fips?` alone.
        Gitlab::Util.get_env('USE_SYSTEM_LIBGCRYPT') == 'true' || fips?
      end

      def match_tag?(tag)
        system(*%W[git describe --exact-match --match #{tag}])
      end

      def is_auto_deploy?
        is_auto_deploy_tag? || is_auto_deploy_branch?
      end

      def is_auto_deploy_tag?
        AUTO_DEPLOY_TAG_REGEX.match?(Build::Info::Git.tag_name)
      end

      def is_auto_deploy_branch?
        Gitlab::Util.get_env('CI_COMMIT_REF_NAME')&.include?('-auto-deploy-')
      end

      def is_patch_release?
        # Major and minor releases have patch component as zero
        Info::Package.semver_version.split(".")[-1] != "0"
      end

      def is_rc_tag?
        Build::Info::Git.tag_name&.include?("+rc")
      end

      def ci_commit_tag?
        Gitlab::Util.get_env('CI_COMMIT_TAG')
      end

      def is_latest_stable_tag?
        match_tag?(Info::Git.latest_stable_tag)
      end

      def is_latest_tag?
        match_tag?(Info::Git.latest_tag)
      end

      def is_nightly?
        Gitlab::Util.get_env('NIGHTLY') == 'true'
      end

      def is_internal_release?
        Gitlab::Util.get_env('INTERNAL_RELEASE') == 'true'
      end

      def is_release_environment?
        Gitlab::Util.get_env('RELEASE_ENVIRONMENT_BUILD') == 'true'
      end

      def no_changes?
        system(*%w[git diff --quiet])
      end

      def run_on_ci?
        Gitlab::Util.get_env('GITLAB_CI')
      end

      def on_tag?
        # On GitLab CI, check if it is a tag pipeline
        return ci_commit_tag? if run_on_ci?

        # Fallback to git describe for local/non-CI environments
        system('git describe --exact-match > /dev/null 2>&1')
      end

      def on_regular_tag?
        on_tag? && !is_auto_deploy_tag?
      end

      def on_stable_branch?
        Build::Info::Git.branch_name&.match?(/^\d+-\d+-stable$/)
      end

      def on_regular_branch?
        Build::Info::Git.branch_name && !on_stable_branch?
      end

      def mr_targetting_stable_branch?
        Build::Info::CI.mr_target_branch_name&.match?(/^\d+-\d+-stable$/)
      end
    end
  end
end
