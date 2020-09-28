# `chef_helper` is a superset of `spec_helper` that configures `chefspec` for
# testing our cookbooks.

require 'spec_helper'
require 'chefspec'
require 'ohai'

# Load our cookbook libraries so we can stub them in our tests
cookbooks = %w(package gitlab gitaly mattermost gitlab-ee letsencrypt monitoring patroni)
cookbooks.each do |cookbook|
  Dir[File.join(__dir__, "../files/gitlab-cookbooks/#{cookbook}/libraries/**/*.rb")].each { |f| require f }
end

def deep_clone(obj)
  Marshal.load(Marshal.dump(obj))
end

# Save the empty state of the Gitlab config singleton
initial_gitlab = deep_clone(Gitlab.save)

RSpec.configure do |config|
  Ohai::Config[:log_level] = :error

  ohai_data = Ohai::System.new.tap { |ohai| ohai.all_plugins(['platform']) }.data
  platform, version = *ohai_data.values_at('platform', 'platform_version')

  begin
    Fauxhai.mock(platform: platform, version: version) { nil }
  rescue Fauxhai::Exception::InvalidPlatform
    puts "Platform #{platform} #{version} not supported. Falling back to ubuntu 16.04"
    platform = 'ubuntu'
    version = '16.04'
  end

  config.platform = platform
  config.version = version

  config.cookbook_path = ['files/gitlab-cookbooks/', 'spec/fixtures/cookbooks']
  config.log_level = :error

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
    allow(VersionHelper).to receive(:version).with('cat /opt/gitlab/embedded/service/mattermost/VERSION').and_return('foobar')
    allow(VersionHelper).to receive(:version).with(/-[-]?version/).and_return('foobar')
    allow_any_instance_of(RedisHelper).to receive(:installed_version).and_return('3.2.12')
    allow_any_instance_of(RedisHelper).to receive(:running_version).and_return('3.2.12')
    stub_command('/sbin/init --version | grep upstart')
    stub_command('systemctl | grep "\-\.mount"')
    # ChefSpec::SoloRunner doesn't support Chef.event_handler, so stub it
    allow(Chef).to receive(:event_handler)

    # Prevent chef converge from reloading any of our previously loaded libraries
    allow(Kernel).to receive(:load).and_call_original
    cookbooks.each do |cookbook|
      allow(Kernel).to receive(:load).with(%r{#{cookbook}/libraries}).and_return(true)
    end

    # Default attributes are frozen;  as that's sometimes a class we really want
    # to mock, just intercept the .freeze call so mocking/unmocking still works
    [PgHelper, GeoPgHelper, GitlabGeoHelper, OmnibusHelper].each do |helper_class|
      allow_any_instance_of(helper_class).to receive(:freeze)
    end

    allow_any_instance_of(PgHelper).to receive(:database_version).and_return("9.2")

    stub_expected_owner?

    # Reset the Gitlab config singelton
    #
    # Gitlab.reset (from mixlib-config) should be enough, but we end up
    # undefining properties.
    initial_gitlab.each do |k, v|
      Gitlab[k] = deep_clone(v)
    end

    # BUG: https://gitlab.com/gitlab-org/omnibus-gitlab/issues/4780
    Gitlab['geo_postgresql']['dir'] = '/var/opt/gitlab/geo-postgresql'

    # Clear services list before each test
    Services.reset_list
  end
end
