require_relative "info.rb"
require_relative "../util.rb"

module Build
  class Check
    class << self
      def is_ee?
        return true if Gitlab::Util.get_env('ee') == 'true'

        File.read('VERSION').include?('-ee')
      end

      def match_tag?(tag)
        system(*%W[git describe --exact-match --match #{tag}])
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
