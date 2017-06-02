require_relative 'build.rb'

class PackageRepository
  def target
    # Override
    return ENV['PACKAGECLOUD_REPO'] if ENV['PACKAGECLOUD_REPO'] && !ENV['PACKAGECLOUD_REPO'].empty?
    # Repository for raspberry pi
    return ENV['RASPBERRY_REPO'] if ENV['RASPBERRY_REPO'] && !ENV['RASPBERRY_REPO'].empty?
    # Repository for nightly build
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

  def repository_for_edition
    is_ee = system('grep -q -E "\-ee" VERSION')
    if ENV['EE'] || is_ee
      "gitlab-ee"
    else
      "gitlab-ce"
    end
  end

  def upload(user)
    puts "Uploading...\n"

    # TODO: upload for real
    package_list.each do |pkg|
      # bin/package_cloud push gitlab/unstable/ubuntu/xenial gitlab-ce.deb  --url=https://packages.gitlab.com
      puts "bin/package_cloud push #{user}/#{pkg} --url=https://packages.gitlab.com"
    end
  end

  private

  def package_list
    list = []

    Dir.glob("pkg/**/*.{deb,rpm}").each do |path|
      platform_path = path.split("/") # ['pkg', 'ubuntu-xenial', 'gitlab-ce.deb']
      platform_path.delete("pkg") # ['ubuntu-xenial', 'gitlab-ce.deb']

      if platform_path.size != 2
        list_dir_contents = `ls -la`
        abort "Found unexpected contents in the directory:\n #{list_dir_contents}"
      end

      platform_name = platform_path[0] # "ubuntu-xenial"
      package_name = platform_path[1] # "gitlab-ce.deb"
      platform = platform_name.gsub("-","/") # "ubuntu/xenial"
      target_repository = target # eg. "unstable"

      # If we detect Enterprise Linux, upload the same package
      # to Scientific and Oracle Linux repositories
      if platform.start_with?("el/")
        ['scientific', 'ol'].each do |distro|
          list << "#{target_repository}/#{platform.gsub('el',distro)} #{package_name}"
        end
      end

      list << "#{target_repository}/#{platform} #{package_name}" # "unstable/ubuntu/xenial gitlab-ce.deb"
    end

    list
  end
end
