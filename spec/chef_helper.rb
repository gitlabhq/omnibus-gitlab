# `chef_helper` is a superset of `spec_helper` that configures `chefspec` for
# testing our cookbooks.

require 'spec_helper'
require 'chefspec'
require 'ohai'

# Load chef specific support libraries to provide common convenience methods for our tests
Dir["./spec/chef/support/**/*.rb"].each { |library| require library }

# Load our cookbook libraries so we can stub them in our tests. package, gitlab
# and gitlab-ee needs to be loaded first as others depend on them for proper
# functionality.
cookbooks = %w[package gitlab gitlab-ee].map { |cookbook| File.join(__dir__, "../files/gitlab-cookbooks/#{cookbook}") }
cookbooks = cookbooks.concat(Dir[File.join(__dir__, "../files/gitlab-cookbooks/*")].select { |d| File.directory?(d) }).uniq

cookbooks.each do |cookbook|
  Dir["#{cookbook}/libraries/**/*.rb"].sort.each { |library| require library }
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

  config.cookbook_path = ['files/gitlab-cookbooks/', 'spec/chef/fixtures/cookbooks']
  config.log_level = :error

  config.define_derived_metadata(file_path: Regexp.new('/spec/chef/')) do |metadata|
    metadata[:type] = :chef
  end

  config.before(:each, type: :chef) do
    ssh_keygen_module = 'gitlab-7.2.0-ssh-keygen'
    authorized_keys_module = 'gitlab-10.5.0-ssh-authorized-keys'
    gitlab_shell_module = 'gitlab-13.5.0-gitlab-shell'
    gitlab_unified_module = 'gitlab'

    stub_command('id -Z').and_return(false)
    stub_command("grep 'CS:123456:respawn:/opt/gitlab/embedded/bin/runsvdir-start' /etc/inittab").and_return('')
    stub_command(%r{\(test -f /var/opt/gitlab/gitlab-rails/upgrade-status/db-migrate-\h+-\) && \(cat /var/opt/gitlab/gitlab-rails/upgrade-status/db-migrate-\h+- | grep -Fx 0\)}).and_return(false)
    stub_command("getenforce | grep Disabled").and_return(true)
    stub_command("semodule -l | grep '^#{ssh_keygen_module}([[:space:]]|$)'").and_return(true)
    stub_command("semodule -l | grep '^#{authorized_keys_module}([[:space:]]|$)'").and_return(true)
    stub_command("semodule -l | grep '^#{gitlab_shell_module}([[:space:]]|$)'").and_return(true)
    stub_command("semodule -l | grep -E '^#{gitlab_unified_module}([[:space:]]|$)'").and_return(true)
    stub_command(%r{set \-x \&\& \[ \-d "[^"]\" \]}).and_return(false)
    stub_command(%r{set \-x \&\& \[ "\$\(stat \-\-printf='[^']*' \$\(readlink -f /[^\)]*\)\) }).and_return(false)
    stub_command('/opt/gitlab/embedded/bin/psql --version').and_return("fake_version")
    allow(VersionHelper).to receive(:version).and_call_original
    allow(VersionHelper).to receive(:version).with('/opt/gitlab/embedded/bin/psql --version').and_return('fake_psql_version')
    allow(VersionHelper).to receive(:version).with('cat /opt/gitlab/embedded/service/mattermost/VERSION').and_return('foobar')
    allow(VersionHelper).to receive(:version).with(/-[-]?version/).and_return('foobar')
    allow_any_instance_of(RedisHelper).to receive(:installed_version).and_return('3.2.12')
    allow_any_instance_of(RedisHelper).to receive(:running_version).and_return('3.2.12')
    allow_any_instance_of(ConsulHelper).to receive(:installed_version).and_return('1.9.6')
    allow_any_instance_of(ConsulHelper).to receive(:running_version).and_return('1.9.6')
    stub_command('/sbin/init --version | grep upstart')
    stub_command('systemctl | grep "\-\.mount"')
    # ChefSpec::SoloRunner doesn't support Chef.event_handler, so stub it
    allow(Chef).to receive(:event_handler)

    # Stub access to /etc/gitlab/initial_root_password
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with('/etc/gitlab/initial_root_password', 'w', 0600).and_yield(double(:file, write: true)).once

    # Prevent chef converge from reloading any of our previously loaded libraries
    allow(Kernel).to receive(:load).and_call_original

    cookbooks.each do |cookbook_path|
      cookbook = File.basename(cookbook_path)
      allow(Kernel).to receive(:load).with(%r{#{cookbook}/libraries}).and_return(true)
    end

    # Default attributes are frozen;  as that's sometimes a class we really want
    # to mock, just intercept the .freeze call so mocking/unmocking still works
    [PgHelper, GeoPgHelper, PgStatusHelper, GitlabGeoHelper, OmnibusHelper].each do |helper_class|
      allow_any_instance_of(helper_class).to receive(:freeze)
    end

    allow_any_instance_of(PgHelper).to receive(:database_version).and_return(PGVersion.new('9.2'))

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
    Gitlab['geo_postgresql']['wal_keep_segments'] = 10
    Gitlab['geo_postgresql']['wal_keep_size'] = 160

    # Clear services list before each test
    Services.reset_list!

    # Clear GitlabCluster config before each test
    GitlabCluster.config.reload!
  end
end
