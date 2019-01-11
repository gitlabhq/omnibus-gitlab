require 'chef_helper'

describe 'gitlab::mattermost' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(env_dir storage_directory)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(external_url: 'http://gitlab.example.com', mattermost_external_url: 'http://mattermost.example.com')
    allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
    allow_any_instance_of(PgHelper).to receive(:database_exists?).and_return(true)
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
    it_behaves_like "enabled service env", "mattermost", "MM_SERVICESETTINGS_SITEURL", 'http://mattermost.example.com'
  end

  context 'when explicitly set' do
    before do
      stub_gitlab_rb(mattermost: {
                       service_site_url: 'http://mattermost.gitlab.example'
                     })
    end

    it_behaves_like "enabled service env", "mattermost", "MM_SERVICESETTINGS_SITEURL", 'http://mattermost.gitlab.example'
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

    it_behaves_like "enabled service env", "mattermost", "MM_GITLABSETTINGS_ENABLE", 'true'
    it_behaves_like "enabled service env", "mattermost", "MM_GITLABSETTINGS_SECRET", 'gitlab_secret'
    it_behaves_like "enabled service env", "mattermost", "MM_GITLABSETTINGS_ID", 'gitlab_id'
    it_behaves_like "enabled service env", "mattermost", "MM_GITLABSETTINGS_SCOPE", 'scope'
    it_behaves_like "enabled service env", "mattermost", "MM_GITLABSETTINGS_AUTHENDPOINT", 'http://gitlab.example.com/oauth/authorize'
    it_behaves_like "enabled service env", "mattermost", "MM_GITLABSETTINGS_TOKENENDPOINT", 'http://gitlab.example.com/oauth/token'
    it_behaves_like "enabled service env", "mattermost", "MM_GITLABSETTINGS_USERAPIENDPOINT", 'http://gitlab.example.com/api/v4/user'
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

    it_behaves_like "enabled service env", "mattermost", "MM_GITLABSETTINGS_ENABLE", 'true'
    it_behaves_like "enabled service env", "mattermost", "MM_GITLABSETTINGS_AUTHENDPOINT", 'https://test-endpoint.example.com/test/auth'
    it_behaves_like "enabled service env", "mattermost", "MM_GITLABSETTINGS_TOKENENDPOINT", 'https://test-endpoint.example.com/test/token'
    it_behaves_like "enabled service env", "mattermost", "MM_GITLABSETTINGS_USERAPIENDPOINT", 'https://test-endpoint.example.com/test/user/api'
  end

  context 'gitlab is added to untrusted internal connections list' do
    context 'when no allowed internal connections are provided by gitlab.rb' do
      it_behaves_like "enabled service env", "mattermost", "MM_SERVICESETTINGS_ALLOWEDUNTRUSTEDINTERNALCONNECTIONS", ' gitlab.example.com'
    end

    context 'when some allowed internal connections are provided by gitlab.rb' do
      before do
        stub_gitlab_rb(mattermost: { enable: true, service_allowed_untrusted_internal_connections: 'localhost' })
      end

      it_behaves_like "enabled service env", "mattermost", "MM_SERVICESETTINGS_ALLOWEDUNTRUSTEDINTERNALCONNECTIONS", 'gitlab.example.com'
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

    context 'does not add gitlab automatically to the list of allowed internal addresses' do
      it_behaves_like "disabled service env", "mattermost", "MM_SERVICESETTINGS_ALLOWEDUNTRUSTEDINTERNALCONNECTIONS", 'gitlab.example.com'
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

    it_behaves_like "enabled service env", "mattermost", "IAM", 'CUSTOMVAR'
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
