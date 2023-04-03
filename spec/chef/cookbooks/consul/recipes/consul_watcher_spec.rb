require 'chef_helper'

RSpec.describe 'consul::watchers' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }
  let(:watcher_conf) { '/var/opt/gitlab/consul/config.d/watcher_postgresql.json' }
  let(:watcher_check) { '/var/opt/gitlab/consul/scripts/failover_postgresql_in_pgbouncer' }
  let(:any_service_conf) { '/var/opt/gitlab/consul/config.d/any_service.conf' }
  let(:excess_watcher_conf) { '/var/opt/gitlab/consul/config.d/watcher_postgresql_old.json' }
  let(:excess_watcher_check) { '/var/opt/gitlab/consul/scripts/failover_postgresql_old_in_pgbouncer' }

  def stub_excess_consul_config_files
    allow(Dir).to receive(:glob).with(anything).and_call_original
    allow(Dir).to receive(:glob).with("/var/opt/gitlab/consul/config.d/*").and_return [excess_watcher_conf, any_service_conf]
    allow(Dir).to receive(:glob).with("/var/opt/gitlab/consul/scripts/*").and_return [excess_watcher_check]
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original

    stub_gitlab_rb(
      consul: {
        enable: true,
        watchers: %w(postgresql)
      }
    )
    stub_excess_consul_config_files
  end

  it 'includes the watcher recipe' do
    expect(chef_run).to include_recipe('consul::watchers')
  end

  it 'creates the watcher config file' do
    rendered = {
      'watches' => [
        {
          'type' => 'service',
          'service' => 'postgresql',
          'args' => [watcher_check]
        }
      ]
    }

    expect(chef_run).to render_file(watcher_conf).with_content { |content|
      expect(JSON.parse(content)).to eq(rendered)
    }
  end

  it 'removes config and watch files of removed watchers' do
    expect(chef_run).to delete_file(excess_watcher_conf)
    expect(chef_run).to delete_file(excess_watcher_check)
    expect(chef_run).to_not delete_file(any_service_conf)
  end

  it 'creates the watcher handler file' do
    expect(chef_run).to render_file(watcher_check)
  end
end
