require 'fileutils'
require_relative "../build.rb"
require_relative "../build/info.rb"
require_relative '../build/omnibus_trigger'
require_relative "../ohai_helper.rb"
require_relative '../version.rb'
require 'net/http'
require 'json'

namespace :build do
  desc 'Start project build'
  task project: ["cache:purge", "check:no_changes"] do
    Build.exec('gitlab') || raise('Build failed')
    Rake::Task["license:check"].invoke
    Rake::Task["build:package:move_to_platform_dir"].invoke
    Rake::Task["build:package:generate_checksums"].invoke
  end

  namespace :docker do
    desc 'Show latest available tag. Includes unstable releases.'
    task :latest_tag do
      puts Build::Info.latest_tag
    end

    desc 'Show latest stable tag.'
    task :latest_stable_tag do
      puts Build::Info.latest_stable_tag
    end
  end

  namespace :package do
    desc "Move packages to OS specific directory"
    task :move_to_platform_dir do
      FileUtils.mv("pkg/version-manifest.json", "pkg/#{Build::Info.package}_#{Build::Info.release_version}.version-manifest.json")
      platform_dir = OhaiHelper.platform_dir
      FileUtils.mv("pkg", platform_dir)
      FileUtils.mkdir("pkg")
      FileUtils.mv(platform_dir, "pkg")
    end

    desc "Generate checksums for each file"
    task :generate_checksums do
      files = Dir.glob('pkg/**/*.{deb,rpm}').select { |f| File.file? f }

      files.each do |file|
        system('sha256sum', file, out: "#{file}.sha256")
      end
    end

    desc "Sync packages to aws"
    task :sync do
      release_bucket = Build::Info.release_bucket
      release_bucket_region = "eu-west-1"
      system(*%W[aws s3 sync pkg/ s3://#{release_bucket} --acl public-read --region #{release_bucket_region}])
      files = Dir.glob('pkg/**/*').select { |f| File.file? f }
      files.each do |file|
        puts file.gsub('pkg', "https://#{release_bucket}.s3.amazonaws.com").gsub('+', '%2B')
      end
    end
  end

  desc "Trigger package and QA builds"
  task :trigger do
    # We need to set the following variables to be able to post a comment with
    # the "downstream" pipeline on the commit under test
    ENV['TOP_UPSTREAM_SOURCE_PROJECT'] ||= ENV['CI_PROJECT_PATH']
    ENV['TOP_UPSTREAM_SOURCE_JOB'] ||= ENV['CI_JOB_URL']
    ENV['TOP_UPSTREAM_SOURCE_SHA'] ||= ENV['CI_COMMIT_SHA']

    Build::OmnibusTrigger.invoke!(post_comment: true).wait!
  end

  desc 'Print the current version'
  task :version do
    # We don't differentiate between CE and EE here since they use the same version file
    puts Gitlab::Version.new('gitlab-rails').print
  end
end
