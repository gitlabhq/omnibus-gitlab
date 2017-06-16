require 'json'
require_relative '../license_analyzer.rb'

desc "Check licenses of bundled softwares"
namespace :license do
  task :check do
    install_dir = File.open('config/projects/gitlab.rb').grep(/install_dir *'/)[0].match(/install_dir[ \t]*'(?<install_dir>.*)'/)['install_dir']
    raise StandardError, "Unable to retrieve install_dir, thus unable to check #{install_dir}/dependency_licenses.json" unless File.exist?(install_dir)

    puts "Checking licenses via the contents of '#{install_dir}/dependency_licenses.json'"
    raise StandardError, "Unable to open #{install_dir}/dependency_licenses.json" unless File.exist?("#{install_dir}/dependency_licenses.json")

    json_data = JSON.parse(File.read("#{install_dir}/dependency_licenses.json"))

    puts "###### BEGIN LICENSE CHECK ######"
    violations = LicenseAnalyzer.analyze(json_data)

    unless violations.empty?
      puts "\n\nProblematic softwares: #{violations.count}"
      violations.each do |violation|
        puts violation
      end
      puts "\n\n"
      raise "Build Aborted due to license violations"
    end
    puts "###### END LICENSE CHECK ######"
  end
end
