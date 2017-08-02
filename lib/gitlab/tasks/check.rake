require_relative "../build/check.rb"

namespace :check do
  desc "Check if working tree is clean"
  task :no_changes do
    raise "Files have been modified after commit" unless Build::Check.no_changes?
  end

  desc "Check if on a tag"
  task :on_tag do
    raise "Build happening not on a tag" unless Build::Check.on_tag?
  end
end
