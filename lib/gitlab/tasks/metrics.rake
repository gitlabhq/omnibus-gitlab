require_relative "../build/check.rb"
require_relative "../build/info.rb"
require_relative "../build/metrics.rb"

namespace :metrics do
  desc "Upgrade gitlab-ee package"
  task :upgrade_package do
    if Build::Metrics.should_upgrade?
      Build::Metrics.configure_gitlab_repo

      # upgrade argument decides if starting of runsv and reconfigure should
      # done explicitly
      Build::Metrics.install_package(Build::Info.previous_version, upgrade: false)
      Build::Metrics.install_package(Build::Info.release_version, upgrade: true)
      duration = Build::Metrics.calculate_duration
      Build::Metrics.append_to_sheet(Build::Info.release_version, duration)
    end
  end
end
