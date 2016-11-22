class PackageRepository

  def target
    return ENV['PACKAGECLOUD_REPO'] if ENV['PACKAGECLOUD_REPO'] && !ENV['PACKAGECLOUD_REPO'].empty?
    return ENV['RASPBERRY_REPO'] if ENV['RASPBERRY_REPO'] && !ENV['RASPBERRY_REPO'].empty?
    return ENV['NIGHTLY_REPO'] if ENV['NIGHTLY_REPO'] && !ENV['NIGHTLY_REPO'].empty?

    rc_repository = repository_for_rc
    if rc_repository
      rc_repository
    else
      repository_for_edition
    end
  end

  def repository_for_rc
    if system('git describe | grep -q -e rc')
      "unstable"
    end
  end

  def repository_for_edition
    is_ee = system('grep -q -E "\-ee" VERSION')
    if ENV['EE'] || is_ee
      "gitlab-ee"
    else
      "gitlab-ce"
    end
  end
end
