require 'chef_helper'

default_dashboards_yml_output = <<-DASHBOARDYML
---
apiVersion: 1
providers:
- name: GitLab Omnibus
  orgId: 1
  folder: GitLab Omnibus
  type: file
  disableDeletion: true
  updateIntervalSeconds: 600
  options:
    path: "/opt/gitlab/embedded/service/grafana-dashboards"
DASHBOARDYML

default_datasources_yml_output = <<-DATASOURCEYML
---
apiVersion: 1
datasources:
- name: GitLab Omnibus
  type: prometheus
  access: proxy
  url: http://localhost:9090
DATASOURCEYML

describe 'monitoring::grafana' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }
  let(:default_vars) do
    {
      'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/',
    }
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
    allow_any_instance_of(PgHelper).to receive(:database_exists?).and_return(true)
  end

  context 'when grafana is enabled' do
    let(:config_template) { chef_run.template('/opt/gitlab/sv/grafana/log/config') }

    before do
      stub_gitlab_rb(
        grafana: { enable: true },
        prometheus: { enable: true }
      )
    end

    it_behaves_like 'enabled runit service', 'grafana', 'root', 'root'

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/grafana/env').with_variables(default_vars)
    end

    it 'populates the files with expected configuration' do
      expect(config_template).to notify('ruby_block[reload_log_service]')

      expect(chef_run).to render_file('/opt/gitlab/sv/grafana/run')
        .with_content { |content|
          expect(content).to match(/exec chpst -P/)
          expect(content).to match(/\/opt\/gitlab\/embedded\/bin\/grafana-server/)
          expect(content).to match(/-config '\/var\/opt\/gitlab\/grafana\/grafana.ini'/)
        }

      expect(chef_run).to render_file('/opt/gitlab/sv/grafana/log/run')
        .with_content(/exec svlogd -tt \/var\/log\/gitlab\/grafana/)
    end

    it 'creates default set of directories' do
      expect(chef_run).to create_directory('/var/log/gitlab/grafana').with(
        owner: 'gitlab-prometheus',
        group: nil,
        mode: '0700'
      )
    end

    it 'creates the configuration file' do
      expect(chef_run).to render_file('/var/opt/gitlab/grafana/grafana.ini')
        .with_content { |content|
          expect(content).to match(/http_addr = localhost/)
          expect(content).to match(/http_port = 3000/)
          expect(content).to match(/root_url = http:\/\/localhost\/-\/grafana/)
          expect(content).not_to match(/\[auth\.gitlab\]/)
        }
    end

    it 'creates a default dashboards file' do
      expect(chef_run).to render_file('/var/opt/gitlab/grafana/provisioning/dashboards/gitlab_dashboards.yml')
        .with_content(default_dashboards_yml_output)
    end

    it 'creates a default datasources file' do
      expect(chef_run).to render_file('/var/opt/gitlab/grafana/provisioning/datasources/gitlab_datasources.yml')
        .with_content(default_datasources_yml_output)
    end
  end

  context 'when grafana is enabled and prometheus is disabled' do
    before do
      stub_gitlab_rb(
        external_url: 'http://gitlab.example.com',
        prometheus: { enable: false },
        grafana: { enable: true }
      )
    end

    it 'should create the gitlab-prometheus account if prometheus is disabled' do
      expect(chef_run).to create_account('Prometheus user and group').with_username('gitlab-prometheus')
    end
  end

  context 'when log dir is changed' do
    before do
      stub_gitlab_rb(
        external_url: 'http://gitlab.example.com',
        grafana: {
          log_directory: 'foo',
          enable: true
        }
      )
    end
    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/grafana/log/run')
        .with_content(/exec svlogd -tt foo/)
    end
  end

  it 'authorizes Grafana with gitlab' do
    stub_gitlab_rb(external_url: 'http://gitlab.example.com')

    allow(GrafanaHelper).to receive(:authorize_with_gitlab)

    expect(chef_run).to run_ruby_block('authorize Grafana with GitLab')
      .at_converge_time
    expect(GrafanaHelper).to receive(:authorize_with_gitlab)
      .with 'http://gitlab.example.com'

    chef_run.ruby_block('authorize Grafana with GitLab').block.call
  end

  context 'with user provided settings' do
    before do
      stub_gitlab_rb(
        external_url: 'https://trailingslash.example.com/',
        grafana: {
          http_addr: '0.0.0.0',
          http_port: 3333,
          enable: true,
          gitlab_application_id: 'appid',
          gitlab_secret: 'secret',
          gitlab_auth_sign_up: false,
          allowed_groups: %w[
            allowed
            also-allowed
          ],
          env: {
            'USER_SETTING' => 'asdf1234'
          },
          dashboards: [
            {
              name: 'GitLab Omnibus',
              orgId: 1,
              folder: 'GitLab Omnibus',
              type: 'file',
              disableDeletion: true,
              updateIntervalSeconds: 600,
              options: {
                path: '/etc/grafana/dashboards',
              },
            },
          ],
        }
      )
    end

    it 'creates a custom dashboards file' do
      expect(chef_run).to render_file('/var/opt/gitlab/grafana/provisioning/dashboards/gitlab_dashboards.yml')
        .with_content { |content|
          expect(content).to match(/options:\n    path: "\/etc\/grafana\/dashboards"\n/)
        }
    end

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/var/opt/gitlab/grafana/grafana.ini')
        .with_content { |content|
          expect(content).to match(/http_addr = 0.0.0.0/)
          expect(content).to match(/http_port = 3333/)
          expect(content).to match(/root_url = https:\/\/trailingslash.example.com\/-\/grafana/)
          expect(content).to match(/\[auth\.gitlab\]\nenabled = true\nallow_sign_up = false/)
          expect(content).to match(/client_id = appid/)
          expect(content).to match(/client_secret = secret/)
          expect(content).to match(/auth_url = https:\/\/trailingslash.example.com\/oauth\/authorize/)
          expect(content).to match(/token_url = https:\/\/trailingslash.example.com\/oauth\/token/)
          expect(content).to match(/api_url = https:\/\/trailingslash.example.com\/api\/v4/)
          expect(content).to match(/allowed_groups = allowed also-allowed/)
          expect(content).to match(/\[metrics\]\n#.+\nenabled = false/)
          expect(content).not_to match(/basic_auth_username/)
          expect(content).not_to match(/basic_auth_password/)
        }
    end

    it 'generates grafana metrics basic auth password when enabled' do
      stub_gitlab_rb(
        grafana: {
          metrics_enabled: true
        }
      )

      expect(chef_run).to render_file('/var/opt/gitlab/grafana/grafana.ini')
        .with_content { |content|
          expect(content).to match(/\[metrics\]\n#.+\nenabled = true/)
          expect(content).not_to match(/basic_auth_username/)
          expect(content).to match(/basic_auth_password = """\S+"""/)
        }
    end

    it 'adds metrics basic_auth_username when set' do
      stub_gitlab_rb(
        grafana: {
          metrics_enabled: true,
          metrics_basic_auth_username: 'user'
        }
      )

      expect(chef_run).to render_file('/var/opt/gitlab/grafana/grafana.ini')
        .with_content { |content|
          expect(content).to match(/\[metrics\]\n#.+\nenabled = true/)
          expect(content).to match(/basic_auth_username = """user"""/)
          expect(content).to match(/basic_auth_password = """\S+"""/)
        }
    end

    it 'can use special chars in metrics basic auth username and password' do
      stub_gitlab_rb(
        grafana: {
          metrics_enabled: true,
          metrics_basic_auth_username: '#user;@',
          metrics_basic_auth_password: 'password_#;@'
        }
      )

      expect(chef_run).to render_file('/var/opt/gitlab/grafana/grafana.ini')
        .with_content { |content|
          expect(content).to match(/\[metrics\]\n#.+\nenabled = true/)
          expect(content).to match(/basic_auth_username = """#user;@"""/)
          expect(content).to match(/basic_auth_password = """password_#;@"""/)
        }
    end

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/grafana/env').with_variables(
        default_vars.merge(
          {
            'USER_SETTING' => 'asdf1234'
          }
        )
      )
    end

    it 'does not deduplicate attributes outside its own scope' do
      queue_groups = ['geo,post_receive,cronjob', 'geo,post_receive,cronjob', 'geo,post_receive,cronjob']

      stub_gitlab_rb(
        grafana: {
          metrics_enabled: true,
        },
        sidekiq_cluster: {
          enable: true,
          queue_groups: queue_groups
        }
      )

      block = chef_run.ruby_block('populate Grafana configuration options')
      block.block.call

      expect(chef_run.node['gitlab']['sidekiq-cluster']['queue_groups']).to eq(queue_groups)
    end
  end
end
