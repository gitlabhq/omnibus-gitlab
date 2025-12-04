# PackageRepository - Factory and base class for package repository implementations
#
# This module provides a factory pattern for creating repository-specific instances
# based on the REPOSITORY_TYPE environment variable.
#
# ## Architecture
#
# The PackageRepository uses an object-oriented design with:
# - A base class (PackageRepository::Base) containing shared functionality
# - Two concrete implementations:
#   - PackageRepository::PackageCloudRepository - for PackageCloud uploads
#   - PackageRepository::PulpRepository - for Pulp server uploads
#
# ## Usage
#
# Create a repository instance using the factory method:
#
#   repo = PackageRepository.new
#   repo.upload(repository_name, dry_run: true)
#
# The factory automatically selects the correct implementation based on
# the REPOSITORY_TYPE environment variable ('packagecloud' or 'pulp').
#
# ## Environment Variables
#
# Common:
# - REPOSITORY_TYPE: 'packagecloud' or 'pulp' (defaults to 'packagecloud')
# - RASPBERRY_REPO: Override repository name for Raspberry Pi builds
#
# PackageCloud-specific:
# - PACKAGECLOUD_USER: Owner of the PackageCloud repository
# - PACKAGECLOUD_REPO: Override repository name
# - PACKAGECLOUD_TOKEN: Authentication token (used by package_cloud CLI)
#
# Pulp-specific:
# - PULP_USER: Owner/prefix for Pulp repositories
# - PULP_REPO: Override repository name

require 'English'

require_relative 'build/info/package'
require_relative 'retriable'
require_relative 'package_repository/base'
require_relative 'package_repository/package_cloud_repository'
require_relative 'package_repository/pulp_repository'
require_relative 'util'

class PackageRepository
  # Repository type constants
  REPOSITORY_TYPE_PACKAGECLOUD = 'packagecloud'.freeze
  REPOSITORY_TYPE_PULP = 'pulp'.freeze

  # Factory method to create the appropriate repository instance
  # based on the REPOSITORY_TYPE environment variable.
  #
  # @return [PackageRepository::Base] An instance of the appropriate repository class
  def self.new
    case repository_type
    when REPOSITORY_TYPE_PACKAGECLOUD
      PackageCloudRepository.new
    when REPOSITORY_TYPE_PULP
      PulpRepository.new
    else
      raise "Unknown repository type: #{repository_type}. Set REPOSITORY_TYPE to 'packagecloud' or 'pulp'."
    end
  end

  # Determines which repository type to use based on environment variable
  #
  # @return [String] The repository type ('packagecloud' or 'pulp')
  def self.repository_type
    # REPOSITORY_TYPE=packagecloud|pulp
    type = Gitlab::Util.get_env('REPOSITORY_TYPE')
    return type if type && !type.empty?

    # Default to PackageCloud
    REPOSITORY_TYPE_PACKAGECLOUD
  end
end
