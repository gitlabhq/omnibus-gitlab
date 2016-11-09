require_relative '../package_repository.rb'

desc 'Package repository where the package will be stored'

namespace :repository do
  task :target do
    PackageRepository.new.target
  end

  task :is_rc do
    PackageRepository.new.is_rc?
  end

  task :is_ee do
    PackageRepository.new.fetch_from_version
  end
end
