require 'chef_helper'

describe 'gitlab::prometheus' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when prometheus is enabled' do
    let(:config_template) { chef_run.template('/var/log/gitlab/prometheus/config') }

    before do
      stub_gitlab_rb(
        prometheus: {
          enable: true
        },
        gitlab_monitor: {
          enable: true
        },
      )
    end

    it_behaves_like 'enabled runit service', 'prometheus', 'root', 'root'

    it 'populates the files with expected configuration' do
      expect(config_template).to notify('ruby_block[reload prometheus svlogd configuration]')

      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content { |content|
          expect(content).to match(/exec chpst -P/)
          expect(content).to match(/\/opt\/gitlab\/embedded\/bin\/prometheus/)
          expect(content).to match(/prometheus.yml/)
        }

      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content { |content|
          expect(content).to match(/scrape_interval: 15s/)
          expect(content).to match(/scrape_timeout: 15s/)
          expect(content).to match(/localhost:9168/)
        }

      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/log/run')
        .with_content(/exec svlogd -tt \/var\/log\/gitlab\/prometheus/)
    end

    it 'creates default set of directories' do
      expect(chef_run).to create_directory('/var/log/gitlab/prometheus').with(
        owner: 'gitlab-prometheus',
        group: nil,
        mode: '0700'
      )
      expect(chef_run).to create_directory('/var/opt/gitlab/prometheus').with(
        owner: 'gitlab-prometheus',
        group: nil,
        mode: '0750'
      )
    end

    it 'should create a gitlab-prometheus user account' do
      expect(chef_run).to create_user('gitlab-prometheus')
    end

    it 'sets a default listen address' do
      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content(/web.listen-address=localhost:9090/)
    end
  end

  context 'with user provided settings' do
    before do
      stub_gitlab_rb(
        prometheus: {
          flags: {
            'storage.local.path' => 'foo'
          },
          listen_address: 'localhost:9898',
          scrape_interval: 11,
          scrape_timeout: 8888,
          enable: true
        }
      )
    end

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content(/web.listen-address=localhost:9898/)
      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content(/storage.local.path=foo/)
    end

    it 'keeps the defaults that the user did not override' do
      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content(/storage.local.memory-chunks=5000/)
      expect(chef_run).to render_file('/opt/gitlab/sv/prometheus/run')
        .with_content(/storage.local.path=foo/)
    end

    it 'renders prometheus.yml with the non-default value' do
      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content(/scrape_timeout: 8888s/)
      expect(chef_run).to render_file('/var/opt/gitlab/prometheus/prometheus.yml')
        .with_content(/scrape_interval: 11/)
    end
  end

  context 'with default configuration' do
    it 'prometheus and all exporters are enabled' do
      expect(chef_run.node['gitlab']['prometheus-monitoring']['enable']).to be true
      Prometheus.services.each do |service|
        expect(chef_run).to include_recipe("gitlab::#{service}")
      end
    end

    context 'when redis and postgres are disabled' do
      before do
        stub_gitlab_rb(
          postgresql: {
            enable: false
          },
          redis: {
            enable: false
          }
        )
      end

      context 'and user did not enable the exporter' do
        it 'postgres exporter is disabled' do
          expect(chef_run).to_not include_recipe('gitlab::postgres-exporter')
        end

        it 'redis exporter is disabled' do
          expect(chef_run).to_not include_recipe('gitlab::redis-exporter')
        end
      end

      context 'and user enabled the exporter' do
        before do
          stub_gitlab_rb(
            postgres_exporter: {
              enable: true
            },
            redis_exporter: {
              enable: true
            }
          )
        end

        it 'postgres exporter is enabled' do
          expect(chef_run).to include_recipe('gitlab::postgres-exporter')
        end

        it 'redis exporter is enabled' do
          expect(chef_run).to include_recipe('gitlab::redis-exporter')
        end
      end
    end

    context 'with user provided settings' do
      before do
        stub_gitlab_rb(
          prometheus_monitoring: {
            enable: false
          }
        )
      end

      it 'disables prometheus and all exporters' do
        expect(chef_run.node['gitlab']['prometheus-monitoring']['enable']).to be false
        Prometheus.services.each do |service|
          expect(chef_run).to include_recipe("gitlab::#{service}_disable")
        end
      end
    end
  end
end
