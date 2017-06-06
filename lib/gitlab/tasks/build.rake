require_relative "../build.rb"

namespace :build do
  desc 'Start project build'
  task :project do
    Build.exec('gitlab')
  end

  namespace :docker do
    desc 'Show package version which will be installed in the Docker image.'
    task :tag do
      puts Build.docker_tag
    end

    desc 'Show latest available tag. Includes unstable releases.'
    task :latest_tag do
      puts Build.latest_tag
    end

    desc 'Show latest stable tag.'
    task :latest_stable_tag do
      puts Build.latest_stable_tag
    end
  end
end
