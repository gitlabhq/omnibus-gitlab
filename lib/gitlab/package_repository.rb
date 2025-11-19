# PackageRepository - Factory and base class for package repository implementations
#
# This module provides a factory pattern for creating repository-specific instances
# based on the REPOSITORY_TYPE environment variable.
#
# ## Architecture
#
# The PackageRepository uses an object-oriented design with PackageRepository::PackageCloudRepository for PackageCloud uploads
#
# ## Usage
#
# Create a repository instance using the factory method:
#
#   repo = PackageRepository.new
#   repo.upload(repository_name, dry_run: true)
#
# The factory automatically selects the correct implementation based on
# the REPOSITORY_TYPE environment variable ('packagecloud').
#
# ## Environment Variables
#
# Common:
# - REPOSITORY_TYPE: 'packagecloud'
# - RASPBERRY_REPO: Override repository name for Raspberry Pi builds
#
# PackageCloud-specific:
# - PACKAGECLOUD_USER: Owner of the PackageCloud repository
# - PACKAGECLOUD_REPO: Override repository name
# - PACKAGECLOUD_TOKEN: Authentication token (used by package_cloud CLI)
#
require 'English'

require_relative 'build/info/package'
require_relative 'retriable'
require_relative 'package_repository/base'
require_relative 'package_repository/package_cloud_repository'
require_relative 'util'

class PackageRepository
  # Repository type constants
  REPOSITORY_TYPE_PACKAGECLOUD = 'packagecloud'.freeze
  # Re-export the exception class for backward compatibility
  PackageUploadError = Base::PackageUploadError

  # Factory method to create the appropriate repository instance
  # based on the REPOSITORY_TYPE environment variable.
  #
  # @return [PackageRepository::Base] An instance of the appropriate repository class
  def self.new
    case repository_type
    when REPOSITORY_TYPE_PACKAGECLOUD
      PackageCloudRepository.new
    else
      raise "Unknown repository type: #{repository_type}. Set REPOSITORY_TYPE to 'packagecloud'."
    end
  end

  # Determines which repository type to use based on environment variable
  #
  # @return [String] The repository type ('packagecloud')
  def self.repository_type
    # REPOSITORY_TYPE=packagecloud
    type = Gitlab::Util.get_env('REPOSITORY_TYPE')
    return type if type && !type.empty?

    # Default to PackageCloud
    REPOSITORY_TYPE_PACKAGECLOUD
  end
end
