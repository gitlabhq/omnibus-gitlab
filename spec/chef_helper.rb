require 'chefspec'
require 'ohai'

# Load our cookbook libraries so we can stub them in our tests
Dir[File.join(__dir__, '../files/gitlab-cookbooks/gitlab/libraries/*.rb')].each { |f| require f }

# Load support libraries to provide common convenience methods for our tests
Dir[File.join(__dir__, 'support/*.rb')].each { |f| require f }

RSpec.configure do |config|
  ohai_data = Ohai::System.new.tap { |ohai| ohai.all_plugins(['platform']) }.data
  platform, version = *ohai_data.values_at('platform', 'platform_version')

  begin
    Fauxhai.mock(platform: platform, version: version)
  rescue Fauxhai::Exception::InvalidPlatform
    puts "Platform #{platform} #{version} not supported. Falling back to ubuntu 14.04"
    platform = 'ubuntu'
    version = '14.04'
  end

  config.platform = platform
  config.version = version

  config.cookbook_path = ['spec/chef/fixture/', 'files/gitlab-cookbooks/']
  config.log_level = :error

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.include(GitlabSpec::Macros)

  config.before do
    stub_command('id -Z').and_return(false)
    stub_command("grep 'CS:123456:respawn:/opt/gitlab/embedded/bin/runsvdir-start' /etc/inittab").and_return('')
    stub_command(%r{\(test -f /var/opt/gitlab/gitlab-rails/upgrade-status/db-migrate-\h+-\) && \(cat /var/opt/gitlab/gitlab-rails/upgrade-status/db-migrate-\h+- | grep -Fx 0\)}).and_return('')
    stub_command("getenforce | grep Disabled").and_return(true)
    stub_command("semodule -l | grep '^#gitlab-7.2.0-ssh-keygen\\s'").and_return(true)
    stub_command(%r{test "\$\(stat \-\-printf='[^']*' /[^\)]*\)" = 'directory }).and_return(false)
    allow_any_instance_of(Chef::Recipe).to receive(:system).with('/sbin/init --version | grep upstart')
    allow_any_instance_of(Chef::Recipe).to receive(:system).with('systemctl | grep "\-\.mount"')
  end
end
