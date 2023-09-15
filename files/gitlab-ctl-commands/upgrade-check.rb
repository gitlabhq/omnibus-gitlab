require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl/upgrade_check"

add_command('upgrade-check', 'Check if the upgrade is acceptable', 2) do
  old_version = ARGV[3]
  new_version = ARGV[4]
  unless GitlabCtl::UpgradeCheck.valid?(old_version)
    old_major = old_version.split('.').first.to_i
    new_major = new_version.split('.').first.to_i
    is_major_upgrade = new_major > old_major
    warn "It seems you are upgrading from #{old_version} to #{new_version}."
    warn "It is required to upgrade to the latest #{GitlabCtl::UpgradeCheck.min_version}.x version first before proceeding."
    warn "Please follow the upgrade documentation at https://docs.gitlab.com/ee/update/index.html#upgrading-to-a-new-major-version" if is_major_upgrade
    warn "Please follow the upgrade documentation at https://docs.gitlab.com/ee/update/#upgrade-paths" unless is_major_upgrade
    Kernel.exit 1
  end
end
