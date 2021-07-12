require_relative "../build/check.rb"
require_relative "../package_size"

namespace :check do
  desc "Check if working tree is clean"
  task :no_changes do
    raise "Files have been modified after commit" unless Build::Check.no_changes?
  end

  desc "Check if on a tag"
  task :on_tag do
    raise "Build happening not on a tag" unless Build::Check.on_tag?
  end

  desc "Check if package size is above threshold"
  task :package_size, :package_sizefile do |_t, args|
    package_sizefile = args['package_sizefile'] || Dir.glob('pkg/*/*.{rpm,deb}.size').first

    raise "File not found." unless File.exist?(package_sizefile)

    PackageSizeCheck.check_and_alert(package_sizefile)
  end
end
