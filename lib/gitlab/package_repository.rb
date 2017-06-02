require_relative 'build.rb'

class PackageRepository
  def target
    return ENV['PACKAGECLOUD_REPO'] if ENV['PACKAGECLOUD_REPO'] && !ENV['PACKAGECLOUD_REPO'].empty?
    return ENV['RASPBERRY_REPO'] if ENV['RASPBERRY_REPO'] && !ENV['RASPBERRY_REPO'].empty?
    return ENV['NIGHTLY_REPO'] if ENV['NIGHTLY_REPO'] && !ENV['NIGHTLY_REPO'].empty?

    rc_repository = repository_for_rc
    if rc_repository
      rc_repository
    else
      Build.package
    end
  end

  def repository_for_rc
    "unstable" if system('git describe | grep -q -e rc')
  end
end
