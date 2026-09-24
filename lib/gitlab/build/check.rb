require 'open3'
require 'timeout'
require_relative '../util'
require_relative 'info/git'
require_relative 'info/package'

module Build
  class Check
    AUTO_DEPLOY_TAG_REGEX = /^\d+\.\d+\.\d+\+[^ ]{7,}\.[^ ]{7,}$/.freeze

    # Version of the Go Cryptographic Module (GOFIPS140) used when building with
    # upstream Go's native FIPS 140-3 support instead of the golang-fips fork.
    # v1.0.0 holds full CMVP certification (#5247). Overridable via the
    # GO_FIPS_MODULE_VERSION environment variable.
    GO_FIPS_MODULE_VERSION = 'v1.0.0'.freeze

    # Bounds the toolchain probe in go_fips_module_check so config load fails
    # with a diagnostic instead of hanging before any build output exists.
    GO_FIPS_TOOLCHAIN_CHECK_TIMEOUT = 30 # seconds

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

      def go_fips_module_version
        Gitlab::Util.get_env('GO_FIPS_MODULE_VERSION') || GO_FIPS_MODULE_VERSION
      end

      # The gate for the Go Cryptographic Module (GOFIPS140). It controls only
      # which crypto module Go compiles against, and nothing else.
      #
      # USE_GO_FIPS_MODULE lets a pipeline request the module on its own.
      #
      # TODO: Remove this entire function once `fips?` is properly implemented.
      def use_go_fips_module?
        Gitlab::Util.get_env('USE_GO_FIPS_MODULE') == 'true' || fips?
      end

      # Single point of control for Go FIPS builds. Called from omnibus.rb before
      # any software definition, so every build command inherits GOFIPS140: a
      # definition's `env:` hash merges over the process environment rather than
      # replacing it. A component opts out only by setting GOFIPS140 to 'off',
      # with a reason. See doc/development/new-software-definition.md.
      def export_go_fips_module_env!
        return unless use_go_fips_module?

        Gitlab::Util.set_env('GOFIPS140', go_fips_module_version)
      end

      # Fails at config load when the builder image's Go toolchain cannot deliver
      # the module, rather than deep inside the first Go component or not at all.
      def verify_go_fips_toolchain!
        return unless use_go_fips_module?

        available, error = go_fips_module_check
        return if available

        raise "This build requests the Go Cryptographic Module #{go_fips_module_version}, but " \
              'the Go toolchain on PATH does not supply it. Either no Go is installed, or the ' \
              'toolchain ships no such module version. Check the builder image and ' \
              "GO_FIPS_MODULE_VERSION.\n#{error}"
      end

      # Probes the toolchain once and reports [available, error].
      #
      # `go version` accepts any GOFIPS140 value, so it verifies nothing.
      # `go list std` resolves the module and fails with "unknown GOFIPS140
      # version" when the toolchain does not ship it. capture3 drains both
      # streams concurrently, so it cannot deadlock on a chatty toolchain, and
      # it yields the stderr that verify_go_fips_toolchain! reports.
      def go_fips_module_check
        Timeout.timeout(GO_FIPS_TOOLCHAIN_CHECK_TIMEOUT) do
          _stdout, stderr, status = Open3.capture3(
            { 'GOTOOLCHAIN' => 'local', 'GOFIPS140' => go_fips_module_version },
            *%w(go list std)
          )

          [status.success?, stderr.strip]
        end
      rescue Timeout::Error
        [false, "the Go toolchain did not respond within #{GO_FIPS_TOOLCHAIN_CHECK_TIMEOUT}s"]
      rescue Errno::ENOENT
        [false, 'no `go` executable is on PATH']
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

      def use_ubt?(allow_arm: false)
        return false unless Gitlab::Util.get_env('UBT_TEST_BUILD') == 'true'

        # Until we get UBT builds for arm64 we should avoid using precompiled binaries.
        return allow_arm if OhaiHelper.arm?

        true
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
