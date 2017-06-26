require_relative '../package_repository.rb'

desc 'Package repository where the package will be stored'

namespace :repository do
  task :target do
    puts PackageRepository.new.target
  end

  task :rc do
    puts PackageRepository.new.repository_for_rc
  end

  task :gitlab_edition do
    puts PackageRepository.new.repository_for_edition
  end

  namespace :upload do
    task :staging, [:staging_repo] do |_t, args|
      staging_repo = args['staging_repo']
      PackageRepository.new.upload(staging_repo)
    end

    task :production do
      PackageRepository.new.upload
    end
  end
end
