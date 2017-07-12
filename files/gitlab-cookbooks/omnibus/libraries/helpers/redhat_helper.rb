class RedhatHelper
  def self.system_is_rhel7?
    platform_family == 'rhel' && platform_version =~ /7\./
  end

  def self.platform_family
    case platform
    when /oracle/, /centos/, /redhat/, /scientific/, /enterpriseenterprise/, /amazon/, /xenserver/, /cloudlinux/, /ibm_powerkvm/, /parallels/
      'rhel'
    else
      'not redhat'
    end
  end

  def self.platform
    contents = read_release_file
    get_redhatish_platform(contents)
  end

  def self.platform_version
    contents = read_release_file
    get_redhatish_version(contents)
  end

  def self.read_release_file
    if File.exist?('/etc/redhat-release')
      File.read('/etc/redhat-release').chomp
    else
      'not redhat'
    end
  end

  # Taken from Ohai
  # https://github.com/chef/ohai/blob/31f6415c853f3070b0399ac2eb09094eb81939d2/lib/ohai/plugins/linux/platform.rb#L23
  def self.get_redhatish_platform(contents)
    contents[/^Red Hat/i] ? 'redhat' : contents[/(\w+)/i, 1].downcase
  end

  # Taken from Ohai
  # https://github.com/chef/ohai/blob/31f6415c853f3070b0399ac2eb09094eb81939d2/lib/ohai/plugins/linux/platform.rb#L27
  def self.get_redhatish_version(contents)
    contents[/Rawhide/i] ? contents[/((\d+) \(Rawhide\))/i, 1].downcase : contents[/release ([\d\.]+)/, 1]
  end
end
