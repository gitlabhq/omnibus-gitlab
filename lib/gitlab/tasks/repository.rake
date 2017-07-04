require_relative '../package_repository.rb'

desc 'Package repository where the package will be stored'

namespace :repository do
  task :target do
    puts PackageRepository.new.target
  end

  task :rc do
    puts PackageRepository.new.repository_for_rc
  end

  namespace :upload do
    task :staging, [:staging_repo, :dry_run] do |_t, args|
      staging_repo = args['staging_repo']
      dry_run = args['dry_run'] || false
      PackageRepository.new.upload(staging_repo, dry_run)
    end

    task :production, [:dry_run] do |_t, args|
      dry_run = args['dry_run'] || false
      PackageRepository.new.upload(nil, dry_run)
    end
  end
end
