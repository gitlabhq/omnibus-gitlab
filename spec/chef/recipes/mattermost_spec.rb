require 'chef_helper'

describe 'gitlab::mattermost' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(env_dir storage_directory)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(external_url: 'http://gitlab.example.com', mattermost_external_url: 'http://mattermost.example.com')
    allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
    allow_any_instance_of(PgHelper).to receive(:database_exists?).and_return(true)
  end

  context 'SiteUrl setting' do
    it 'is set when mattermost_external_url is set' do
      expect(chef_run).to render_file('/var/opt/gitlab/mattermost/config.json')
        .with_content(%r{"SiteURL": "http://mattermost.example.com",})
    end

    context 'when explicitly set' do
      before do
        stub_gitlab_rb(mattermost: {
                         service_site_url: 'http://mattermost.gitlab.example'
                       })
      end

      it 'is not overriden by mattermost_external_url' do
        expect(chef_run).to render_file('/var/opt/gitlab/mattermost/config.json')
          .with_content(%r{"SiteURL": "http://mattermost.gitlab.example",})
      end
    end
  end

  it 'authorizes mattermost with gitlab' do
    allow(MattermostHelper).to receive(:authorize_with_gitlab)

    expect(chef_run).to run_ruby_block('authorize mattermost with gitlab')
      .at_converge_time
    expect(MattermostHelper).to receive(:authorize_with_gitlab)
      .with 'http://gitlab.example.com'

    chef_run.ruby_block('authorize mattermost with gitlab').block.call
  end

  it 'populates mattermost configuration options to node attributes' do
    stub_gitlab_rb(mattermost: { enable: true, gitlab_id: 'old' })
    allow(MattermostHelper).to receive(:authorize_with_gitlab) do |url|
      Gitlab['mattermost']['gitlab_id'] = 'new'
    end

    expect(chef_run).to run_ruby_block('populate mattermost configuration options')
      .at_converge_time

    chef_run.ruby_block('authorize mattermost with gitlab').block.call
    chef_run.ruby_block('populate mattermost configuration options').block.call

    expect(chef_run.node['mattermost']['gitlab_id']).to eq 'new'
  end

  it 'creates mattermost configuration file with gitlab settings' do
    stub_gitlab_rb(mattermost: {
                     enable: true,
                     gitlab_enable: true,
                     gitlab_id: 'gitlab_id',
                     gitlab_secret: 'gitlab_secret',
                     gitlab_scope: 'scope',
                   })

    expect(chef_run).to render_file('/var/opt/gitlab/mattermost/config.json')
      .with_content { |content|
        config = JSON.parse(content)
        expect(config).to have_key 'GitLabSettings'
        expect(config['GitLabSettings']['Enable']).to be true
        expect(config['GitLabSettings']['Secret']).to eq 'gitlab_secret'
        expect(config['GitLabSettings']['Id']).to eq 'gitlab_id'
        expect(config['GitLabSettings']['Scope']).to eq 'scope'
        expect(config['GitLabSettings']['AuthEndpoint']).to eq 'http://gitlab.example.com/oauth/authorize'
        expect(config['GitLabSettings']['TokenEndpoint']).to eq 'http://gitlab.example.com/oauth/token'
        expect(config['GitLabSettings']['UserApiEndpoint']).to eq 'http://gitlab.example.com/api/v4/user'
      }
  end

  it 'allows overrides to the mattermost settings regarding GitLab endpoints' do
    stub_gitlab_rb(mattermost: {
                     enable: true,
                     gitlab_enable: true,
                     gitlab_auth_endpoint: 'https://test-endpoint.example.com/test/auth',
                     gitlab_token_endpoint: 'https://test-endpoint.example.com/test/token',
                     gitlab_user_api_endpoint: 'https://test-endpoint.example.com/test/user/api'
                   })

    expect(chef_run).to render_file('/var/opt/gitlab/mattermost/config.json')
      .with_content { |content|
        config = JSON.parse(content)
        expect(config).to have_key 'GitLabSettings'
        expect(config['GitLabSettings']['Enable']).to be true
        expect(config['GitLabSettings']['AuthEndpoint']).to eq 'https://test-endpoint.example.com/test/auth'
        expect(config['GitLabSettings']['TokenEndpoint']).to eq 'https://test-endpoint.example.com/test/token'
        expect(config['GitLabSettings']['UserApiEndpoint']).to eq 'https://test-endpoint.example.com/test/user/api'
      }
  end

  it 'render mattermost configuration values correctly when arrays are expected' do
    stub_gitlab_rb(mattermost: {
                     enable: true,
                     sql_data_source_replicas: [],
                     sql_data_source_search_replicas: []
                   })

    expect(chef_run).to render_file('/var/opt/gitlab/mattermost/config.json')
      .with_content { |content|
        config = JSON.parse(content)
        expect(config).to have_key 'SqlSettings'
        expect(config['SqlSettings']['DataSourceReplicas']).to be_instance_of(Array)
        expect(config['SqlSettings']['DataSourceSearchReplicas']).to be_instance_of(Array)
      }
  end

  it 'creates mattermost configuration file in specified home folder' do
    stub_gitlab_rb(mattermost: {
                     enable: true,
                     home: '/var/local/gitlab/mattermost',
                   })

    expect(chef_run).to render_file('/opt/gitlab/sv/mattermost/run').with_content(/\-config \/var\/local\/gitlab\/mattermost\/config.json/)
  end

  shared_examples 'gitlab address set in allowed internal connections' do
    it 'includes gitlab in the list of allowed internal addresses' do
      expect(chef_run).to render_file('/var/opt/gitlab/mattermost/config.json')
        .with_content { |content|
          config = JSON.parse(content)
          expect(config).to have_key 'ServiceSettings'
          expect(config['ServiceSettings']['AllowedUntrustedInternalConnections']).to match(/gitlab\.example\.com/)
        }
    end
  end

  context 'when no allowed internal connections are provided by gitlab.rb' do
    it_behaves_like 'gitlab address set in allowed internal connections'
  end

  context 'when some allowed internal connections are provided by gitlab.rb' do
    before do
      stub_gitlab_rb(mattermost: { enable: true, service_allowed_untrusted_internal_connections: 'localhost' })
    end

    it_behaves_like 'gitlab address set in allowed internal connections'
  end

  shared_examples 'no gitlab authorization performed' do
    it 'does not authorize mattermost with gitlab' do
      expect(chef_run).not_to run_ruby_block('authorize mattermost with gitlab')
    end
  end

  context 'when gitlab authentication parameters are specified explicitly' do
    before { stub_gitlab_rb(mattermost: { enable: true, gitlab_enable: true }) }

    it_behaves_like 'no gitlab authorization performed'
  end

  context 'when gitlab-rails is disabled' do
    before { stub_gitlab_rb(gitlab_rails: { enable: false }) }

    it_behaves_like 'no gitlab authorization performed'

    it 'does not add gitlab automatically to the list of allowed internal addresses' do
      expect(chef_run).to render_file('/var/opt/gitlab/mattermost/config.json').with_content { |content|
        config = JSON.parse(content)
        expect(config['ServiceSettings']['AllowedUntrustedInternalConnections']).not_to match(/gitlab\.example\.com/)
      }
    end
  end

  context 'when database is not running' do
    before { allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(false) }

    it_behaves_like 'no gitlab authorization performed'
  end

  context 'when mattermost database does not exist' do
    before { allow_any_instance_of(PgHelper).to receive(:database_exists?).and_return(false) }

    it_behaves_like 'no gitlab authorization performed'
  end

  context 'when a custom env variable is specified' do
    before do
      stub_gitlab_rb(mattermost: { env: { 'IAM' => 'CUSTOMVAR' } })
    end

    it_behaves_like "enabled mattermost env", "IAM", 'CUSTOMVAR'
  end
end
