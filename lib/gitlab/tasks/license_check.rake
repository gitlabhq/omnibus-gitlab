desc "Check licenses of bundled softwares"
namespace :license do
  task :check do

    good = Regexp.union([/^MIT/, /^LGPL/, /^Apache/, /^Ruby/, /^BSD-[23]{1}/, /^ISO/])
    bad = Regexp.union([/^GPL/, /^AGPL/])

    puts "###### BEGIN LICENSE CHECK ######"

    install_dir = File.open('config/projects/gitlab.rb').grep(/install_dir *"/)[0].match(/install_dir[ \t]*"(?<install_dir>.*)"/)['install_dir']

    if File.exists?(install_dir)
      puts "Checking licenses via the contents of '#{install_dir}/LICENSE'"
    else
      raise StandardError, "Unable to retrieve install_dir, thus unable to check #{install_dir}/LICENSE"
    end

    unless File.exists?("#{install_dir}/LICENSE")

      raise StandardError, "Unable to open #{install_dir}/LICENSE"
    end

    reg = Regexp.compile(/product bundles (?<software>.*?),?\n(,\n)?.*available under a "(?<license>.*)" License/)
    matches = File.read("#{install_dir}/LICENSE").scan(reg)
    matches.each do |software, license|
      if license.match(good)
        puts "Good   : #{software} uses #{license}"
      elsif license.match(bad)
        puts "Check  ! #{software} uses #{license}"
      else
        puts "Unknown? #{software} uses #{license}"
      end
    end

    puts "###### END LICENSE CHECK ######"
  end
end
