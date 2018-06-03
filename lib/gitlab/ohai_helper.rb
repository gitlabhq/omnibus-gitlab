require 'ohai'

class OhaiHelper
  class << self
    # This prints something like 'ubuntu-xenial'
    def platform_dir
      os, codename = fetch_os_with_codename

      "#{os}-#{codename}"
    end

    # This prints something like 'ubuntu/xenial'; used for packagecloud uploads
    def repo_string
      os, codename = fetch_os_with_codename

      "#{os}/#{codename}"
    end

    def fetch_os_with_codename
      os = os_platform
      version = os_platform_version

      if (os == :unknown) || (version == :unknown)
        abort "Unsupported OS: #{ohai.values_at('platform', 'platform_version').inspect}"
      end

      [os, version]
    end

    def os_platform
      case ohai['platform']
      when 'ubuntu'
        'ubuntu'
      when 'debian', 'raspbian'
        verify_platform
      when 'centos'
        'el'
      when 'opensuse', 'opensuseleap'
        'opensuse'
      when 'suse'
        'sles'
      else
        :unknown
      end
    end

    def os_platform_version
      version = :unknown

      case ohai['platform']
      when 'ubuntu'
        case ohai['platform_version']
        when /^12\.04/
          version = 'precise'
        when /^14\.04/
          version = 'trusty'
        when /^16\.04/
          version = 'xenial'
        when /^18\.04/
          version = 'bionic'
        end
      when 'debian', 'raspbian'
        case ohai['platform_version']
        when /^7\./
          version = 'wheezy'
        when /^8\./
          version = 'jessie'
        when /^9\./
          version = 'stretch'
        end
      when 'centos'
        case ohai['platform_version']
        when /^6\./
          version = '6'
        when /^7\./
          version = '7'
        end
      when 'opensuse', 'opensuseleap'
        version = ohai['platform_version']
      when 'suse'
        case ohai['platform_version']
        when /^12\./
          version = '12.2'
        when /^11\./
          version = '11.4'
        end
      end

      version
    end

    def ohai
      @ohai ||= Ohai::System.new.tap do |oh|
        oh.all_plugins(['platform'])
      end.data
    end

    def verify_platform
      # We have no way to verify whether we are building for RPI
      # as the builder machine will report that it is Debian.
      # Since we don't officially release  arm packages, it should be safe to
      # assume that if we are on a Debian machine on arm, we are building for
      # Raspbian.
      if /armv/.match?(ohai['kernel']['machine'])
        'raspbian'
      else
        ohai['platform']
      end
    end
  end
end
