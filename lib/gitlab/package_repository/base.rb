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

    # Abstract method: Must be implemented by subclasses
    # @return [String] The target repository name
    def target
      raise NotImplementedError, "#{self.class} must implement #target"
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
end
