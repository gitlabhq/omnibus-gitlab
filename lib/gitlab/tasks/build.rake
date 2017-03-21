require_relative "../build.rb"

namespace :build do
  task :project do
    Build.exec('gitlab')
  end
end
