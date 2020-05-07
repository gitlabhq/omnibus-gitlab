require 'chef_helper'

describe 'gitlab::mattermost' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }
  let(:default_vars) do
    {
      'MM_FILESETTINGS_DIRECTORY' => '/var/opt/gitlab/mattermost/data',
      'MM_GITLABSETTINGS_AUTHENDPOINT' => 'http://gitlab.example.com/oauth/authorize',
      'MM_GITLABSETTINGS_ENABLE' => 'false',
      'MM_GITLABSETTINGS_ID' => '',
      'MM_GITLABSETTINGS_SCOPE' => '',
      'MM_GITLABSETTINGS_SECRET' => '',
      'MM_GITLABSETTINGS_TOKENENDPOINT' => 'http://gitlab.example.com/oauth/token',
      'MM_GITLABSETTINGS_USERAPIENDPOINT' => 'http://gitlab.example.com/api/v4/user',
      'MM_LOGSETTINGS_FILELOCATION' => '/var/log/gitlab/mattermost',
      'MM_PLUGINSETTINGS_CLIENTDIRECTORY' => '/var/opt/gitlab/mattermost/client-plugins',
      'MM_PLUGINSETTINGS_DIRECTORY' => '/var/opt/gitlab/mattermost/plugins',
      'MM_SERVICESETTINGS_ALLOWEDUNTRUSTEDINTERNALCONNECTIONS' => ' gitlab.example.com',
      'MM_SERVICESETTINGS_ENABLEAPITEAMDELETION' => 'true',
      'MM_SERVICESETTINGS_LISTENADDRESS' => '127.0.0.1:8065',
      'MM_SERVICESETTINGS_SITEURL' => 'http://mattermost.example.com',
      'MM_SQLSETTINGS_ATRESTENCRYPTKEY' => 'asdf1234',
      'MM_SQLSETTINGS_DATASOURCE' => 'user=gitlab_mattermost host=/var/opt/gitlab/postgresql port=5432 dbname=mattermost_production',
      'MM_SQLSETTINGS_DRIVERNAME' => 'postgres',
      'MM_TEAMSETTINGS_SITENAME' => 'GitLab Mattermost',
      'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/',
    }
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(external_url: 'http://gitlab.example.com', mattermost_external_url: 'http://mattermost.example.com')
    allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
    allow_any_instance_of(PgHelper).to receive(:database_exists?).and_return(true)
    allow(SecretsHelper).to receive(:generate_hex).and_return('asdf1234')
  end

  context 'by default' do
    it 'creates a default VERSION file and restarts service' do
      expect(chef_run).to create_version_file('Create version file for Mattermost').with(
        version_file_path: '/var/opt/gitlab/mattermost/VERSION',
        version_check_cmd: 'cat /opt/gitlab/embedded/service/mattermost/VERSION'
      )

      expect(chef_run.version_file('Create version file for Mattermost')).to notify('runit_service[mattermost]').to(:hup)
    end
  end

  context 'service user and group' do
    context 'default values' do
      it_behaves_like "enabled runit service", "mattermost", "root", "root", "mattermost", "mattermost"
    end

    context 'custom user and group' do
      before do
        stub_gitlab_rb(
          external_url: 'http://gitlab.example.com',
          mattermost_external_url: 'http://mattermost.example.com',
          mattermost: {
            username: 'foo',
            group: 'bar'
          }
        )
      end

      it_behaves_like "enabled runit service", "mattermost", "root", "root", "foo", "bar"
    end
  end

  context 'SiteUrl setting' do
    context 'default value' do
      it 'creates necessary env variable files' do
        expect(chef_run).to create_env_dir('/opt/gitlab/etc/mattermost/env').with(
          variables: default_vars
        )
      end
    end

    context 'when explicitly set' do
      before do
        stub_gitlab_rb(mattermost: {
                         service_site_url: 'http://mattermost.gitlab.example'
                       })
      end

      it 'creates necessary env variable files' do
        expect(chef_run).to create_env_dir('/opt/gitlab/etc/mattermost/env').with(
          variables: default_vars.merge({ 'MM_SERVICESETTINGS_SITEURL' => 'http://mattermost.gitlab.example' })
        )
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

  context 'populate env variables based on provided gitlab settings' do
    before do
      stub_gitlab_rb(mattermost: {
                       enable: true,
                       gitlab_enable: true,
                       gitlab_id: 'gitlab_id',
                       gitlab_secret: 'gitlab_secret',
                       gitlab_scope: 'scope',
                     })
    end

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/mattermost/env').with(
        variables: default_vars.merge(
          {
            'MM_GITLABSETTINGS_ENABLE' => 'true',
            'MM_GITLABSETTINGS_SECRET' => 'gitlab_secret',
            'MM_GITLABSETTINGS_ID' => 'gitlab_id',
            'MM_GITLABSETTINGS_SCOPE' => 'scope',
            'MM_GITLABSETTINGS_AUTHENDPOINT' => 'http://gitlab.example.com/oauth/authorize',
            'MM_GITLABSETTINGS_TOKENENDPOINT' => 'http://gitlab.example.com/oauth/token',
            'MM_GITLABSETTINGS_USERAPIENDPOINT' => 'http://gitlab.example.com/api/v4/user',
          }
        )
      )
    end
  end

  context 'allows overrides to the mattermost settings regarding GitLab endpoints' do
    before do
      stub_gitlab_rb(mattermost: {
                       enable: true,
                       gitlab_enable: true,
                       gitlab_auth_endpoint: 'https://test-endpoint.example.com/test/auth',
                       gitlab_token_endpoint: 'https://test-endpoint.example.com/test/token',
                       gitlab_user_api_endpoint: 'https://test-endpoint.example.com/test/user/api'
                     })
    end

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/mattermost/env').with(
        variables: default_vars.merge(
          {
            'MM_GITLABSETTINGS_ENABLE' => 'true',
            'MM_GITLABSETTINGS_AUTHENDPOINT' => 'https://test-endpoint.example.com/test/auth',
            'MM_GITLABSETTINGS_TOKENENDPOINT' => 'https://test-endpoint.example.com/test/token',
            'MM_GITLABSETTINGS_USERAPIENDPOINT' => 'https://test-endpoint.example.com/test/user/api'
          }
        )
      )
    end
  end

  context 'gitlab is added to untrusted internal connections list' do
    context 'when no allowed internal connections are provided by gitlab.rb' do
      it 'creates necessary env variable files' do
        expect(chef_run).to create_env_dir('/opt/gitlab/etc/mattermost/env').with(variables: default_vars)
      end
    end

    context 'when some allowed internal connections are provided by gitlab.rb' do
      before do
        stub_gitlab_rb(mattermost: { enable: true, service_allowed_untrusted_internal_connections: 'localhost' })
      end

      it 'creates necessary env variable files' do
        expect(chef_run).to create_env_dir('/opt/gitlab/etc/mattermost/env').with(
          variables: default_vars.merge(
            {
              'MM_SERVICESETTINGS_ALLOWEDUNTRUSTEDINTERNALCONNECTIONS' => 'localhost gitlab.example.com'
            }
          )
        )
      end
    end
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
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/mattermost/env').with(
        variables: default_vars.merge(
          {
            'MM_SERVICESETTINGS_ALLOWEDUNTRUSTEDINTERNALCONNECTIONS' => nil
          }
        )
      )
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

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/mattermost/env').with(
        variables: default_vars.merge(
          {
            'IAM' => 'CUSTOMVAR'
          }
        )
      )
    end
  end

  describe 'letsencrypt' do
    before do
      stub_gitlab_rb(
        external_url: 'https://gitlab.example.com',
        mattermost_external_url: 'https://mattermost.example.com'
      )

      allow(File).to receive(:exist?).and_call_original
    end

    describe 'HTTP to HTTPS redirection' do
      context 'by default' do
        it 'is enabled' do
          expect(chef_run).to render_file('/var/opt/gitlab/nginx/conf/gitlab-mattermost-http.conf').with_content("return 301 https://mattermost.example.com:443$request_uri;")
        end
      end

      context 'if disabled in gitlab.rb' do
        before do
          stub_gitlab_rb(
            external_url: 'https://gitlab.example.com',
            mattermost_external_url: 'https://mattermost.example.com',
            mattermost_nginx: {
              redirect_http_to_https: false
            }
          )
        end

        it 'is disabled' do
          expect(chef_run).to render_file('/var/opt/gitlab/nginx/conf/gitlab-mattermost-http.conf')
          expect(chef_run).not_to render_file('/var/opt/gitlab/nginx/conf/gitlab-mattermost.conf').with_content("return 301 https://mattermost.example.com:443$request_uri;")
        end
      end
    end

    context 'default certificate file is missing' do
      before do
        allow(File).to receive(:exist?).with('/etc/gitlab/ssl/mattermost.example.com.crt').and_return(false)
      end

      it 'adds itself to letsencrypt alt_names' do
        expect(chef_run.node['letsencrypt']['alt_names']).to eql(['mattermost.example.com'])
      end

      it 'is reflected in the acme_selfsigned' do
        expect(chef_run).to create_acme_selfsigned('gitlab.example.com').with(
          alt_names: ['mattermost.example.com']
        )
      end
    end

    context 'default certificate file is present' do
      before do
        allow(File).to receive(:exist?).with('/etc/gitlab/ssl/mattermost.example.com.crt').and_return(true)
      end

      it 'does not alter letsencrypt alt_names' do
        expect(chef_run.node['letsencrypt']['alt_names']).to eql([])
      end

      it 'is reflected in the acme_selfsigned' do
        expect(chef_run).to create_acme_selfsigned('gitlab.example.com').with(
          alt_names: []
        )
      end
    end
  end
end
