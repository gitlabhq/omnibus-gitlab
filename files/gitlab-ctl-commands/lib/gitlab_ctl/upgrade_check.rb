require 'semverse'

module GitlabCtl
  class UpgradeCheck
    MIN_VERSION = '13.0'.freeze

    class <<self
      def valid?(ov, nv)
        # If old_version is nil, this is a fresh install
        return true if ov.nil?

        old_version = Semverse::Version.new(ov)
        new_version = Semverse::Version.new(nv)

        if old_version.major < new_version.major
          return false if old_version.minor != MIN_VERSION
        end

        true
      end
    end
  end
end
