module GitlabCtl
  class UpgradeCheck
    MIN_VERSION = '13.0'.freeze

    class <<self
      def valid?(ov, nv)
        # If old_version is nil, this is a fresh install
        return true if ov.nil?

        old_version_major = ov.split('.').first
        old_version_minor = ov.split('.')[0..1].join('.')
        new_version_major = nv.split('.').first

        if old_version_major < new_version_major
          return false if old_version_minor != MIN_VERSION
        end

        true
      end
    end
  end
end
