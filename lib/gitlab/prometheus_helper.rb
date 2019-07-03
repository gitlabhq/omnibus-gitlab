require 'time'

module Prometheus
  class VersionFlags
    def initialize(version)
      common_version = 'github.com/prometheus/common/version'

      @ldflags = [
        "-X #{common_version}.Version=#{version.print(false)}",
        "-X #{common_version}.Branch=master",
        "-X #{common_version}.BuildUser=GitLab-Omnibus"
      ]
    end

    def print_ldflags
      @ldflags.join(' ')
    end
  end
end
