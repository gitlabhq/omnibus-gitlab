require 'chefspec'
require 'ohai'
require 'fantaskspec'
require 'knapsack'

Knapsack::Adapters::RSpecAdapter.bind if ENV['USE_KNAPSACK']

# Load our cookbook libraries so we can stub them in our tests
Dir[File.join(__dir__, '../files/gitlab-cookbooks/package/libraries/**/*.rb')].each { |f| require f }
Dir[File.join(__dir__, '../files/gitlab-cookbooks/gitlab/libraries/*.rb')].each { |f| require f }
Dir[File.join(__dir__, '../files/gitlab-cookbooks/gitaly/libraries/*.rb')].each { |f| require f }
Dir[File.join(__dir__, '../files/gitlab-cookbooks/mattermost/libraries/*.rb')].each { |f| require f }
Dir[File.join(__dir__, '../files/gitlab-cookbooks/gitlab-ee/libraries/*.rb')].each { |f| require f }

# Load support libraries to provide common convenience methods for our tests
Dir[File.join(__dir__, 'support/*.rb')].each { |f| require f }

RSpec.configure do |config|
  def mock_file_load(file)
    allow(Kernel).to receive(:load).and_call_original
    allow(Kernel).to receive(:load).with(file).and_return(true)
  end

  Ohai::Config[:log_level] = :error

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

  config.cookbook_path = ['files/gitlab-cookbooks/', 'spec/fixtures/cookbooks']
  config.log_level = :error

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.include(GitlabSpec::Macros)

  config.before do
    stub_command('id -Z').and_return(false)
    stub_command("grep 'CS:123456:respawn:/opt/gitlab/embedded/bin/runsvdir-start' /etc/inittab").and_return('')
    stub_command(%r{\(test -f /var/opt/gitlab/gitlab-rails/upgrade-status/db-migrate-\h+-\) && \(cat /var/opt/gitlab/gitlab-rails/upgrade-status/db-migrate-\h+- | grep -Fx 0\)}).and_return(false)
    stub_command("getenforce | grep Disabled").and_return(true)
    stub_command("semodule -l | grep '^#gitlab-7.2.0-ssh-keygen\\s'").and_return(true)
    stub_command(%r{set \-x \&\& \[ \-d "[^"]\" \]}).and_return(false)
    stub_command(%r{set \-x \&\& \[ "\$\(stat \-\-printf='[^']*' \$\(readlink -f /[^\)]*\)\) }).and_return(false)
    stub_command('/opt/gitlab/embedded/bin/psql --version').and_return("fake_version")
    allow(VersionHelper).to receive(:version).and_call_original
    allow(VersionHelper).to receive(:version).with('/opt/gitlab/embedded/bin/psql --version').and_return('fake_psql_version')
    allow_any_instance_of(Chef::Recipe).to receive(:system).with('/sbin/init --version | grep upstart')
    allow_any_instance_of(Chef::Recipe).to receive(:system).with('systemctl | grep "\-\.mount"')
    # ChefSpec::SoloRunner doesn't support Chef.event_handler, so stub it
    allow(Chef).to receive(:event_handler)
    # Prevent chef converge from reloading the storage helper library, which would override our helper stub
    mock_file_load(%r{gitlab/libraries/storage_directory_helper})
    mock_file_load(%r{gitlab/libraries/helper})
    allow_any_instance_of(PgHelper).to receive(:database_version).and_return("9.2")

    stub_expected_owner?
    # Clear services list before each test
    Services.reset_list
  end
end
