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

      abort "Unsupported OS: #{ohai.values_at('platform', 'platform_version').inspect}" if (os == :unknown) || (version == :unknown)

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

    def get_ubuntu_version
      case ohai['platform_version']
      when /^12\.04/
        'precise'
      when /^14\.04/
        'trusty'
      when /^16\.04/
        'xenial'
      when /^18\.04/
        'bionic'
      end
    end

    def get_debian_version
      case ohai['platform_version']
      when /^7\./
        'wheezy'
      when /^8\./
        'jessie'
      when /^9\./
        'stretch'
      when /^10\./
        'buster'
      end
    end

    def get_centos_version
      case ohai['platform_version']
      when /^6\./
        '6'
      when /^7\./
        '7'
      when /^8\./
        '8'
      end
    end

    def get_opensuse_version
      ohai['platform_version']
    end

    def get_suse_version
      case ohai['platform_version']
      when /^12\.2/
        '12.2'
      when /^12\.5/
        '12.5'
      when /^11\./
        '11.4'
      end
    end

    def os_platform_version
      version = :unknown

      case ohai['platform']
      when 'ubuntu'
        version = get_ubuntu_version
      when 'debian', 'raspbian'
        version = get_debian_version
      when 'centos'
        version = get_centos_version
      when 'opensuse', 'opensuseleap'
        version = get_opensuse_version
      when 'suse'
        version = get_suse_version
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
