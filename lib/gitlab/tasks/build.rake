require_relative "../build.rb"

namespace :build do
  desc 'Start project build'
  task :project do
    Build.exec('gitlab')
  end

  desc 'Show which package is being built, CE/EE'
  task :package do
    puts Build.package
  end
end
