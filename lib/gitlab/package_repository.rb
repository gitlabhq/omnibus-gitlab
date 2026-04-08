# PackageRepository - Entry point for package repository operations.
#
# Always uses PulpRepository for package uploads.
#
# ## Usage
#
#   repo = PackageRepository.new
#   repo.upload(repository_name, dry_run: true)

require 'English'

require_relative 'build/info/package'
require_relative 'retriable'
require_relative 'package_repository/base'
require_relative 'package_repository/pulp_repository'
require_relative 'util'

class PackageRepository
  def self.new
    PulpRepository.new
  end
end
