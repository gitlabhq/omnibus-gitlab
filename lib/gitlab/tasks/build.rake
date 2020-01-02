require 'fileutils'
require_relative "../build.rb"
require_relative "../build/info.rb"
require_relative '../build/omnibus_trigger'
require_relative "../ohai_helper.rb"
require_relative '../version.rb'
require_relative "../util.rb"
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
    Gitlab::Util.set_env_if_missing('TOP_UPSTREAM_SOURCE_PROJECT', Gitlab::Util.get_env('CI_PROJECT_PATH'))
    Gitlab::Util.set_env_if_missing('TOP_UPSTREAM_SOURCE_JOB', Gitlab::Util.get_env('CI_JOB_URL'))
    Gitlab::Util.set_env_if_missing('TOP_UPSTREAM_SOURCE_SHA', Gitlab::Util.get_env('CI_COMMIT_SHA'))
    Gitlab::Util.set_env_if_missing('TOP_UPSTREAM_SOURCE_REF', Gitlab::Util.get_env('CI_COMMIT_REF_NAME'))

    Build::OmnibusTrigger.invoke!(post_comment: true).wait!
  end

  desc 'Print the current version'
  task :version do
    # We don't differentiate between CE and EE here since they use the same version file
    puts Gitlab::Version.new('gitlab-rails').print
  end

  desc 'Print SHAs of GitLab components'
  task :component_shas do
    version_manifest_file = Dir.glob('pkg/**/*version-manifest.json').first
    return unless version_manifest_file

    puts "#### SHAs of GitLab Components"
    json_content = JSON.parse(File.read(version_manifest_file))
    %w[gitlab-rails gitaly gitlab-pages gitlab-shell gitlab-workhorse].each do |component|
      puts "#{component} : #{json_content['software'][component]['locked_version']}"
    end
  end
end
