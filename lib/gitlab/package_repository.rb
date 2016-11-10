class PackageRepository

  def target
    return ENV['PACKAGECLOUD_REPO'] if ENV['PACKAGECLOUD_REPO'] && !ENV['PACKAGECLOUD_REPO'].empty?
    return ENV['RASPBERRY_REPO'] if ENV['RASPBERRY_REPO'] && !ENV['RASPBERRY_REPO'].empty?
    return ENV['NIGHTLY_REPO'] if ENV['NIGHTLY_REPO'] && !ENV['NIGHTLY_REPO'].empty?

    rc = is_rc?
    if rc
      rc
    else
      fetch_from_version
    end
  end

  def is_rc?
    if system('git describe | grep -q -e rc')
      "unstable"
    end
  end

  def fetch_from_version
    is_ee = system('grep -q -E "\-ee" VERSION')
    if ENV['EE'] || is_ee
      "gitlab-ee"
    else
      "gitlab-ce"
    end
  end
end
