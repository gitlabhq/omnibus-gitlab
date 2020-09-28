require 'English'
require_relative 'build/info.rb'
require_relative "util.rb"

class PackageRepository
  PACKAGE_GLOB = "pkg/**/*.{deb,rpm}".freeze

  def target
    # Override
    return Gitlab::Util.get_env('PACKAGECLOUD_REPO') if Gitlab::Util.get_env('PACKAGECLOUD_REPO') && !Gitlab::Util.get_env('PACKAGECLOUD_REPO').empty?
    # Repository for raspberry pi
    return Gitlab::Util.get_env('RASPBERRY_REPO') if Gitlab::Util.get_env('RASPBERRY_REPO') && !Gitlab::Util.get_env('RASPBERRY_REPO').empty?

    rc_repository = repository_for_rc
    rc_repository || Build::Info.package
  end

  def repository_for_rc
    "unstable" if IO.popen(%w[git describe], &:read).include?('rc')
  end

  def validate(dry_run)
    Dir.glob(PACKAGE_GLOB).each do |pkg|
      checksum_filename = pkg + '.sha256'

      raise "Package #{pkg} is missing its checksum file #{checksum_filename}" unless dry_run || File.exist?(checksum_filename)

      success = verify_checksum(checksum_filename, dry_run)

      raise "Aborting, package #{pkg} has an invalid checksum!" unless success
    end
  end

  def upload(repository = nil, dry_run = false)
    if upload_user.nil?
      puts "User for uploading to package server not specified!"
      return
    end

    # For CentOS 6 and 7 we will upload the same package to Scientific and Oracle Linux
    # For all other OSs, we only upload one package.
    upload_list = package_list(repository)
    raise "No packages found for upload. Are artifacts available?" if upload_list.empty?

    validate(dry_run)

    upload_list.each do |pkg|
      # bin/package_cloud push gitlab/unstable/ubuntu/xenial gitlab-ce.deb  --url=https://packages.gitlab.com
      cmd = "LC_ALL='en_US.UTF-8' bin/package_cloud push #{upload_user}/#{pkg} --url=https://packages.gitlab.com"
      puts "Uploading...\n"

      if dry_run
        puts cmd
      else
        result = `#{cmd}`

        if $CHILD_STATUS.exitstatus == 1
          raise "Upload to package server failed!." unless /filename: has already been taken/.match?(result)

          puts "Package #{pkg} has already been uploaded, skipping.\n"
        end
      end
    end
  end

  private

  def package_list(repository)
    list = []

    Dir.glob(PACKAGE_GLOB).each do |path|
      platform_path = path.split("/") # ['pkg', 'ubuntu-xenial_aarch64', 'gitlab-ce.deb']

      if platform_path.size != 3
        list_dir_contents = `ls -la pkg/`
        raise "Found unexpected contents in the directory:\n #{list_dir_contents}"
      end

      platform_name = platform_path[1] # "ubuntu-xenial_aarch64"
      package_name = platform_path[2] # "gitlab-ce.deb"
      package_path = "#{platform_path[0]}/#{platform_name}/#{package_name}"
      platform = platform_name.gsub(/_.*/, '').tr("-", "/") # "ubuntu/xenial"
      target_repository = repository || target # staging override or the rest, eg. "unstable"

      # If we detect Enterprise Linux 6/7, upload the same package
      # to Scientific and Oracle Linux repositories
      if platform.match?(/^el\/[6,7]/)
        %w(scientific ol).each do |distro|
          platform_path = platform.gsub('el', distro)

          list << "#{target_repository}/#{platform_path} #{package_path}"
        end
      end

      list << "#{target_repository}/#{platform} #{package_path}" # "unstable/ubuntu/xenial gitlab-ce.deb"
    end

    list
  end

  def upload_user
    Gitlab::Util.get_env('PACKAGECLOUD_USER') if Gitlab::Util.get_env('PACKAGECLOUD_USER') && !Gitlab::Util.get_env('PACKAGECLOUD_USER').empty?
  end

  def verify_checksum(filename, dry_run)
    cmd = %W[sha256sum -c #{filename}]

    if dry_run
      puts cmd.join(' ')
      true
    else
      system(*cmd)
    end
  end
end
