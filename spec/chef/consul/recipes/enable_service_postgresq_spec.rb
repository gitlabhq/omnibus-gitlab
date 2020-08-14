require 'chef_helper'

RSpec.describe 'consul::enable_service_postgresql' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'default' do
    before do
      stub_gitlab_rb(
        consul: {
          enable: true,
          services: %w(postgresql)
        }
      )
    end

    it 'renders the service configuration file' do
      rendered = {
        'service' => {
          'name' => 'postgresql',
          'address' => '',
          'port' => 5432,
          'check' => {
            'id' => 'service:postgresql',
            'args' => ["/opt/gitlab/bin/gitlab-ctl", "repmgr-check-master"],
            'interval' => '10s',
            'status' => 'failing'
          }
        },
        'watches' => [
          {
            'type' => 'keyprefix',
            'prefix' => 'gitlab/ha/postgresql/failed_masters/',
            'args' => ["/opt/gitlab/bin/gitlab-ctl", "consul", "watchers", "handle-failed-master"]
          }
        ]
      }
      expect(chef_run).to render_file('/var/opt/gitlab/consul/config.d/postgresql_service.json').with_content { |content|
        expect(JSON.parse(content)).to eq(rendered)
      }
    end
  end

  context 'when patroni is enabled' do
    before do
      stub_gitlab_rb(
        patroni: {
          enable: true
        },
        consul: {
          enable: true,
          services: %w(postgresql)
        }
      )
    end

    it 'renders the service configuration file' do
      rendered = {
        'service' => {
          'name' => 'postgresql',
          'address' => '',
          'port' => 5432,
          'check' => {
            'id' => 'service:postgresql',
            'args' => ['/opt/gitlab/bin/gitlab-ctl', 'patroni', 'check-leader'],
            'interval' => '10s',
            'status' => 'failing'
          }
        }
      }
      expect(chef_run).to render_file('/var/opt/gitlab/consul/config.d/postgresql_service.json').with_content { |content|
        expect(JSON.parse(content)).to eq(rendered)
      }
    end
  end
end
