require 'English'

require_relative '../build/info/package'
require_relative '../retriable'
require_relative '../util'

class PackageRepository
  # Base class for package repository implementations.
  # Provides common functionality for uploading packages to different repository types.
  class Base
    PackageUploadError = Class.new(StandardError)

    def initialize
      # Subclasses can override this if they need custom initialization
    end

    # Abstract method: Must be implemented by subclasses
    # @param repository [String, nil] Optional repository override
    # @param dry_run [Boolean] Whether to perform a dry run without actual upload
    def upload(repository = nil, dry_run = false)
      raise NotImplementedError, "#{self.class} must implement #upload"
    end

    # Returns the target repository name
    # Priority: PULP_REPO env var > PACKAGECLOUD_REPO env var > RASPBERRY_REPO env var > RC repository > Package name
    # For legacy reason, in most places PACKAGECLOUD_REPO is still used. If PULP_REPO is specified, it must be for Pulp
    # @return [String] The target repository name
    def target
      # Override for Pulp (with legacy PackageCloud fallback)
      return Gitlab::Util.get_env('PULP_REPO') if Gitlab::Util.get_env('PULP_REPO') && !Gitlab::Util.get_env('PULP_REPO').empty?
      return Gitlab::Util.get_env('PACKAGECLOUD_REPO') if Gitlab::Util.get_env('PACKAGECLOUD_REPO') && !Gitlab::Util.get_env('PACKAGECLOUD_REPO').empty?

      # Repository for raspberry pi
      return Gitlab::Util.get_env('RASPBERRY_REPO') if Gitlab::Util.get_env('RASPBERRY_REPO') && !Gitlab::Util.get_env('RASPBERRY_REPO').empty?

      rc_repository = repository_for_rc
      rc_repository || Build::Info::Package.name
    end

    # Abstract method: Must be implemented by subclasses
    # @return [String, nil] The user/owner of the repository
    def user
      raise NotImplementedError, "#{self.class} must implement #user"
    end

    # Determines if the current build is a release candidate
    # @return [String, nil] Returns 'unstable' for RC builds, nil otherwise
    def repository_for_rc
      "unstable" if IO.popen(%w[git describe], &:read).include?('rc')
    end

    # Validates all packages by checking their checksums
    # @param dry_run [Boolean] Whether to perform a dry run
    # @raise [RuntimeError] If a package is missing its checksum file or has an invalid checksum
    def validate(dry_run)
      Build::Info::Package.file_list.each do |pkg|
        checksum_filename = "#{pkg}.sha256"

        raise "Package #{pkg} is missing its checksum file #{checksum_filename}" unless dry_run || File.exist?(checksum_filename)

        success = verify_checksum(checksum_filename, dry_run)

        raise "Aborting, package #{pkg} has an invalid checksum!" unless success
      end
    end

    private

    # Validates the package directory structure
    # @param path [String] The package path to validate
    # @raise [RuntimeError] If the directory structure is unexpected
    # @return [Array<String>] The validated platform path array
    def validate_package_path(path)
      platform_path = path.split("/") # ['pkg', 'ubuntu-xenial_aarch64', 'gitlab-ee_18.6.deb']

      return platform_path if platform_path.size == 3

      list_dir_contents = Dir.glob("pkg/**/*").join("\n")
      raise "Found unexpected contents in the directory:\n#{list_dir_contents}"
    end

    # Adds additional platform entries for cross-compatible distributions
    # Subclasses must implement this to add platform-specific entries
    # @param list [Array] The list to append additional entries to
    # @param platform [String] The platform identifier
    # @param args [Hash] Additional arguments needed to create entries
    # @return [void]
    def add_additional_platforms(list, platform, **args)
      raise NotImplementedError, "#{self.class} must implement #add_additional_platforms"
    end

    # Gets the exit status of the last child process
    # @return [Integer] The exit status code
    def child_process_status
      $CHILD_STATUS.exitstatus
    end

    # Verifies the checksum of a package file
    # @param filename [String] Path to the checksum file
    # @param dry_run [Boolean] Whether to perform a dry run
    # @return [Boolean] True if checksum is valid, false otherwise
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

  # Re-export the exception class at the module level for easier access
  PackageUploadError = Base::PackageUploadError
end
