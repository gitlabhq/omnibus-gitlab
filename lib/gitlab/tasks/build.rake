namespace :build do
  task :package, :log_level do |_t, args|
    args.with_defaults(
      log_level: 'info'
    )
    sh %( bundle exec omnibus build gitlab --log-level #{args[:log_level]} )
  end
end

desc 'Build a package for the current platform'
task :build, :log_level do |_t, args|
  Rake::Task['build:package'].invoke(args[:log_level])
end
