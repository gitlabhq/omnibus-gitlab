require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl/upgrade_check"

add_command('upgrade-check', 'Check if the upgrade is acceptable', 2) do
  old_version = ARGV[3]
  new_version = ARGV[4]
  unless GitlabCtl::UpgradeCheck.valid?(old_version, new_version)
    warn "It seems you are upgrading from major version #{old_version.split('.').first} to major version #{new_version.split('.').first}."
    warn "It is required to upgrade to the latest #{GitlabCtl::UpgradeCheck::MIN_VERSION}.x version first before proceeding."
    warn "Please follow the upgrade documentation at https://docs.gitlab.com/ee/policy/maintenance.html#upgrading-major-versions"
    Kernel.exit 1
  end
end
