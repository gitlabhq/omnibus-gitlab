require_relative 'base'

class PackageRepository
  # PackageCloud repository implementation for uploading packages to PackageCloud.
  # Uses the package_cloud CLI to upload packages to various Linux distributions.
  class PackageCloudRepository < Base
    # Returns the target repository name for PackageCloud
    # Priority: PACKAGECLOUD_REPO env var > RASPBERRY_REPO env var > RC repository > Package name
    # @return [String] The target repository name
    def target
      # Override for PackageCloud
      return Gitlab::Util.get_env('PACKAGECLOUD_REPO') if Gitlab::Util.get_env('PACKAGECLOUD_REPO') && !Gitlab::Util.get_env('PACKAGECLOUD_REPO').empty?
      # Repository for raspberry pi
      return Gitlab::Util.get_env('RASPBERRY_REPO') if Gitlab::Util.get_env('RASPBERRY_REPO') && !Gitlab::Util.get_env('RASPBERRY_REPO').empty?

      rc_repository = repository_for_rc
      rc_repository || Build::Info::Package.name
    end

    # Returns the PackageCloud user/owner
    # @return [String, nil] The PackageCloud user from PACKAGECLOUD_USER environment variable
    def user
      # Even though the variable says "upload user", this is actually the user
      # who owns the repository to which packages are being uploaded. This
      # information is only used to generate the path to the repository - the
      # user who actually does the upload is known by the token.
      Gitlab::Util.get_env('PACKAGECLOUD_USER') if Gitlab::Util.get_env('PACKAGECLOUD_USER') && !Gitlab::Util.get_env('PACKAGECLOUD_USER').empty?
    end

    # Uploads packages to PackageCloud repository
    # @param repository [String, nil] Optional repository override
    # @param dry_run [Boolean] Whether to perform a dry run without actual upload
    def upload(repository = nil, dry_run = false)
      if user.nil?
        puts "Owner of the repository to which packages are being uploaded not specified! Set `PACKAGECLOUD_USER` environment variable."
        return
      end

      # For CentOS 8 and 9 we upload the same package to the Oracle Linux repository.
      # For OpenSUSE Leap we upload the same package to the SLES repository.
      upload_list = package_list(repository)
      raise "No packages found for upload. Are artifacts available?" if upload_list.empty?

      validate(dry_run)

      upload_list.each do |pkg|
        # bin/package_cloud push gitlab/unstable/ubuntu/xenial gitlab-ce.deb  --url=https://packages.gitlab.com
        cmd = "LC_ALL='en_US.UTF-8' bin/package_cloud push #{user}/#{pkg} --url=https://packages.gitlab.com"
        puts "Uploading...\n"

        puts "Running the command: #{cmd}"

        next if dry_run

        Retriable.with_context(:package_publish, on: PackageUploadError) do
          result = `#{cmd}`

          if child_process_status == 1
            unless /filename: has already been taken/.match?(result)
              puts 'Upload to package server failed!.'
              puts "The command returned the output: #{result}"
              raise PackageUploadError, "Upload to package server failed!."
            end

            puts "Package #{pkg} has already been uploaded, skipping.\n"
          end
        end
      end
    end

    private

    # Generates the list of packages to upload to PackageCloud
    # @param repository [String, nil] Optional repository override
    # @return [Array<String>] Array of package upload paths
    def package_list(repository)
      list = []

      Build::Info::Package.file_list.each do |path|
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

        list << "#{target_repository}/#{platform} #{package_path}" # "unstable/ubuntu/xenial gitlab-ce.deb"

        # Also upload Enterprise Linux to Oracle Linux repo.
        if platform.start_with?("el/")
          additional_platform = platform.gsub('el', 'ol')
          list << "#{target_repository}/#{additional_platform} #{package_path}"
        end

        # Also upload OpenSUSE Leap to repo.
        if platform.start_with?("opensuse/")
          additional_platform = platform.gsub('opensuse', 'sles')
          list << "#{target_repository}/#{additional_platform} #{package_path}"
        end
      end

      list
    end
  end
end
