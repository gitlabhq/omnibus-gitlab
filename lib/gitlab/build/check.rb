require_relative "info.rb"

module Build
  class Check
    class << self
      def is_ee?
        return true if ENV['ee'] == 'true'

        system('grep -q -E "\-ee" VERSION')
      end

      def match_tag?(tag)
        system("git describe --exact-match --match #{tag}")
      end

      def is_patch_release?
        # Major and minor releases have patch component as zero
        Info.semver_version.split(".")[-1] != "0"
      end

      def is_rc_release?
        `git describe --exact-match`.include?("+rc")
      end

      def add_latest_tag?
        match_tag?(Info.latest_stable_tag)
      end

      def add_rc_tag?
        match_tag?(Info.latest_tag)
      end

      def add_nightly_tag?
        ENV['NIGHTLY'] == 'true'
      end

      def no_changes?
        system("git diff --quiet")
      end

      def on_tag?
        system("git describe --exact-match")
      end
    end
  end
end
