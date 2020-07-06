require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl/upgrade_check"

add_command('upgrade-check', 'Check if the upgrade is acceptable', 2) do
  unless GitlabCtl::UpgradeCheck.valid?(ARGV[2], ARGV[3])
    warn "It seems you are upgrading from major version ${OLD_MAJOR_VERSION} to major version ${NEW_MAJOR_VERSION}."
    warn "It is required to upgrade to the latest ${MIN_VERSION}.x version first before proceeding."
    warn "Please follow the upgrade documentation at https://docs.gitlab.com/ee/policy/maintenance.html#upgrade-recommendations"
    Kernel.exit 1
  end
end
