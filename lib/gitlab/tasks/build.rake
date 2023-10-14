require 'fileutils'
require 'json'
require 'net/http'

require_relative '../build'
require_relative '../build/check'
require_relative '../build/facts'
require_relative '../build/info/git'
require_relative '../build/info/package'
require_relative '../gcloud_helper'
require_relative '../ohai_helper'
require_relative '../package_size'
require_relative '../util'
require_relative '../version'

namespace :build do
  desc 'Start project build'
  task project: ["cache:purge", "check:no_changes"] do
    Gitlab::Util.section('build:project') do
      Build.exec('gitlab') || raise('Build failed')
    end

    Rake::Task["license:check"].invoke
    Rake::Task["build:package:move_to_platform_dir"].invoke
    Rake::Task["build:package:generate_checksums"].invoke
    Rake::Task["build:package:generate_sizefile"].invoke
  end

  namespace :docker do
    desc 'Show latest available tag. Includes unstable releases.'
    task :latest_tag do
      puts Build::Info::Git.latest_tag
    end

    desc 'Show latest stable tag.'
    task :latest_stable_tag do
      puts Build::Info::Git.latest_stable_tag
    end
  end

  namespace :package do
    desc "Move packages to OS specific directory"
    task :move_to_platform_dir do
      FileUtils.mv("pkg/version-manifest.json", "pkg/#{Build::Info::Package.name}_#{Build::Info::Package.release_version}.version-manifest.json")
      platform_dir = OhaiHelper.platform_dir
      FileUtils.mv("pkg", platform_dir)
      FileUtils.mkdir("pkg")
      FileUtils.mv(platform_dir, "pkg")
    end

    desc "Generate checksums for each file"
    task :generate_checksums do
      Gitlab::Util.section('build:package:generate_checksums') do
        files = Dir.glob('pkg/**/*.{deb,rpm}').select { |f| File.file? f }
        files.each do |file|
          system('sha256sum', file, out: "#{file}.sha256")
        end
      end
    end

    desc "Generate sizefile for each file"
    task :generate_sizefile do
      Gitlab::Util.section('build:package:generate_sizefile') do
        files = Dir.glob('pkg/**/*.{deb,rpm}').select { |f| File.file? f }
        if files.empty?
          # We are probably inside Trigger:package_size_check job.
          PackageSizeCheck.fetch_sizefile
        else
          PackageSizeCheck.generate_sizefiles(files)
        end
      end
    end

    desc "Sync packages to gcp"
    task :sync do
      Gitlab::Util.section('build:package:sync', collapsed: Build::Check.on_tag?) do
        GCloudHelper.upload_packages_and_print_urls('pkg/')
      end
    end

    desc "Package name"
    task :name do
      puts Build::Info::Package.name
    end

    desc 'Print the package name-version string to install the specific version of package'
    task :name_version do
      puts Build::Info::Package.name_version
    end
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

    Gitlab::Util.section('build:component_shas') do
      puts "#### SHAs of GitLab Components"
      Build::Facts.get_component_shas(version_manifest_file).each do |component, sha|
        puts "#{component} : #{sha}"
      end
    end
  end

  desc 'Write build related facts to file'
  task :generate_facts do
    FileUtils.mkdir_p('build_facts')

    Build::Facts.generate
  end
end
