class SystemdHelper
  class << self
    SYSTEMD_VERSION_REGEX ||= /systemd (?<version>\d+).*/.freeze

    def systemd_version
      systemd_lines = IO.popen(%w[systemctl --version], &:read)
      systemd_version_line = systemd_lines.split("\n").first
      SYSTEMD_VERSION_REGEX.match(systemd_version_line)['version'].to_i
    rescue StandardError
      # Return a negative value so the greater-than check never succeeds
      -999
    end
  end
end
