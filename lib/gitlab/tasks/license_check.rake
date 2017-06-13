require 'json'

desc "Check licenses of bundled softwares"
namespace :license do
  task :check do
    good = Regexp.union([/^MIT/, /^LGPL/, /^Apache/, /^Ruby/, /^BSD-[23]{1}/, /^ISO/])
    bad = Regexp.union([/^GPL/, /^AGPL/])

    puts "###### BEGIN LICENSE CHECK ######"

    install_dir = File.open('config/projects/gitlab.rb').grep(/install_dir *'/)[0].match(/install_dir[ \t]*'(?<install_dir>.*)'/)['install_dir']
    raise StandardError, "Unable to retrieve install_dir, thus unable to check #{install_dir}/dependency_licenses.json" unless File.exist?(install_dir)
    puts "Checking licenses via the contents of '#{install_dir}/dependency_licenses.json'"

    unless File.exist?("#{install_dir}/dependency_licenses.json")

      raise StandardError, "Unable to open #{install_dir}/dependency_licenses.json"
    end

    content = File.read("#{install_dir}/dependency_licenses.json")
    JSON.parse(content).each do |dependency, attributes|
      license = attributes['license']
      version = attributes['version']
      if license.match(good)
        puts "Good   : #{dependency} - #{version} uses #{license}"
      elsif license.match(bad)
        puts "Check  ! #{dependency} - #{version} uses #{license}"
      else
        puts "Unknown? #{dependency} - #{version} uses #{license}"
      end
    end
    puts "###### END LICENSE CHECK ######"
  end
end
