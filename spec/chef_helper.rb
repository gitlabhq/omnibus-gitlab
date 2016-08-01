require 'chefspec'

RSpec.configure do |config|
  config.cookbook_path = ['spec/chef/fixture/', 'files/gitlab-cookbooks/']
  config.log_level = :error
  config.platform = 'ubuntu'
  config.version = '14.04'

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.before do
    stub_command('id -Z').and_return('')
    stub_command("grep 'CS:123456:respawn:/opt/gitlab/embedded/bin/runsvdir-start' /etc/inittab").and_return('')
    stub_command(%r{\(test -f /var/opt/gitlab/gitlab-rails/upgrade-status/db-migrate-\h+-\) && \(cat /var/opt/gitlab/gitlab-rails/upgrade-status/db-migrate-\h+- | grep -Fx 0\)}).and_return('')
    allow_any_instance_of(Chef::Recipe).to receive(:system).with('/sbin/init --version | grep upstart')
    allow_any_instance_of(Chef::Recipe).to receive(:system).with('systemctl | grep "\-\.mount"')
  end
end
