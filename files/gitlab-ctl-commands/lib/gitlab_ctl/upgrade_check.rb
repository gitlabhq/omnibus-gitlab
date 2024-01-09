module GitlabCtl
  class UpgradeCheck
    class <<self
      def valid?(ov)
        # If old_version is nil, this is a fresh install
        return true if ov.nil?

        old_version_major = ov.split('.')[0].to_i
        old_version_minor = ov.split('.')[1].to_i
        min_version = min_version()
        min_version_major = min_version.split('.')[0].to_i
        min_version_minor = min_version.split('.')[1].to_i

        minimum_version_detected = old_version_major == min_version_major && old_version_minor >= min_version_minor
        minimum_version_detected || old_version_major > min_version_major
      end

      def min_version
        ENV['MIN_VERSION'] || '16.7'.freeze
      end
    end
  end
end
