module GitlabCtl
  class UpgradeCheck
    MIN_VERSION = ENV['MIN_VERSION'] || '14.9'.freeze

    class <<self
      def valid?(ov, nv)
        # If old_version is nil, this is a fresh install
        return true if ov.nil?

        old_version_major = ov.split('.').first
        old_version_minor = ov.split('.')[0..1].join('.')
        new_version_major = nv.split('.').first

        if old_version_major <= new_version_major
          return false if Gem::Version.new(old_version_minor) < Gem::Version.new(MIN_VERSION)
        end

        true
      end
    end
  end
end
