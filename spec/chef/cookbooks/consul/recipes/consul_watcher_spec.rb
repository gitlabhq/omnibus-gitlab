require 'chef_helper'

RSpec.describe 'consul::watchers' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }
  let(:watcher_conf) { '/var/opt/gitlab/consul/config.d/watcher_postgresql.json' }
  let(:watcher_check) { '/var/opt/gitlab/consul/scripts/failover_pgbouncer' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original

    stub_gitlab_rb(
      consul: {
        enable: true,
        watchers: %w(postgresql)
      }
    )
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

  it 'creates the watcher handler file' do
    expect(chef_run).to render_file(watcher_check)
  end
end
