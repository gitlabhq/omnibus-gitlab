class Build
  class << self
    def exec(project, log_level)
      sh "bundle exec omnibus build #{project} --log-level #{log_level}"
    end
  end
end

namespace :build do
  task :package, :log_level do |_t, args|
    args.with_defaults(
      log_level: 'info'
    )
    Build.exec('gitlab', args[:log_level])
  end
end

desc 'Build a package for the current platform'
task :build, :log_level do |_t, args|
  Rake::Task['build:package'].invoke(args[:log_level])
end
