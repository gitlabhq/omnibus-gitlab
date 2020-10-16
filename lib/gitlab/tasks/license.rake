require 'fileutils'
require 'json'
require_relative "../build/info.rb"
require_relative "../build/check.rb"
require_relative '../license/analyzer.rb'
require_relative '../license/uploader.rb'
require_relative '../license/collector.rb'
require_relative "../util.rb"

namespace :license do
  desc "Check licenses of bundled softwares"
  task :check do
    Gitlab::Util.section_start('license:check')

    install_dir = File.open('config/projects/gitlab.rb').grep(/install_dir *'/)[0].match(/install_dir[ \t]*'(?<install_dir>.*)'/)['install_dir']
    raise StandardError, "Unable to retrieve install_dir, thus unable to check #{install_dir}/dependency_licenses.json" unless File.exist?(install_dir)

    puts "Checking licenses via the contents of '#{install_dir}/dependency_licenses.json'"
    raise StandardError, "Unable to open #{install_dir}/dependency_licenses.json" unless File.exist?("#{install_dir}/dependency_licenses.json")

    json_data = JSON.parse(File.read("#{install_dir}/dependency_licenses.json"))

    puts "###### BEGIN LICENSE CHECK ######"
    violations = License::Analyzer.analyze(json_data)

    unless violations.empty?
      puts "\n\nProblematic softwares: #{violations.count}"
      violations.each do |violation|
        puts violation
      end
      puts "\n\n"
      raise "Build Aborted due to license violations"
    end
    puts "###### END LICENSE CHECK ######"

    Gitlab::Util.section_end
  end

  desc "Generate license file of current release and push to AWS bucket"
  task :upload do
    Gitlab::Util.section_start('license:upload')

    # This is done on Ubuntu 18.04 non-rc tag pipeline only
    License::Uploader.new.execute unless Build::Check.is_rc_tag?

    Gitlab::Util.section_end
  end

  desc "Collect all license files and generate index page"
  task :generate_pages do
    Gitlab::Util.section_start('license:generate_pages')
    License::Collector.new.execute
    Gitlab::Util.section_end
  end
end
