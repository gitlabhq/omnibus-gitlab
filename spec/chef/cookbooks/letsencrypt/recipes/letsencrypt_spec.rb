require 'chef_helper'

RSpec.describe 'enabling letsencrypt' do
  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(external_url: 'https://fakehost.example.com')
  end

  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  context 'unspecified uses LetsEncrypt.should_auto_enable?' do
    it 'true' do
      allow(LetsEncrypt).to receive(:should_auto_enable?).and_return(true)

      expect(chef_run).to include_recipe('letsencrypt::enable')
    end

    it 'false' do
      allow(LetsEncrypt).to receive(:should_auto_enable?).and_return(false)

      expect(chef_run).to include_recipe('letsencrypt::disable')
      expect(chef_run).not_to include_recipe('letsencrypt::enable')
    end
  end

  context 'specified' do
    it 'true' do
      stub_gitlab_rb(letsencrypt: { enable: true })

      expect(chef_run).to include_recipe('letsencrypt::enable')
    end

    it 'false' do
      stub_gitlab_rb(letsencrypt: { enable: false })

      expect(chef_run).not_to include_recipe('letsencrypt::enable')
    end
  end
end

RSpec.describe 'letsencrypt::enable' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  let(:node) { chef_run.node }

  let(:https_redirect_block) { %r!server { ## HTTPS redirect server(.*)} ## end HTTPS redirect server!m }
  let(:https_block) { %r!server { ## HTTPS server(.*)} ## end HTTPS server!m }
  let(:acme_challenge_block) { %r!\s*location /.well-known/acme-challenge/ {! }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow(LetsEncrypt).to receive(:should_auto_enable?).and_return(false)
    allow_any_instance_of(OmnibusHelper).to receive(:service_up?).and_return(false)
    allow_any_instance_of(OmnibusHelper).to receive(:service_up?).with('nginx').and_return(true)
  end

  context 'default' do
    it 'does not run' do
      expect(chef_run).not_to include_recipe('letsencrypt::enable')
    end
  end

  context 'enabled' do
    before do
      stub_gitlab_rb(
        external_url: 'https://fakehost.example.com',
        mattermost_external_url: 'https://fakemost.example.com',
        registry_external_url: 'https://fakereg.example.com',
        letsencrypt: {
          enable: true
        }
      )
    end

    it 'is included' do
      expect(chef_run).to include_recipe('letsencrypt::enable')
    end

    context 'when updating nginx configurations' do
      using RSpec::Parameterized::TableSyntax

      where(:redirect_config_key, :nginx_config_file) do
        'nginx' | '/var/opt/gitlab/nginx/conf/gitlab-http.conf'
        'mattermost-nginx' | '/var/opt/gitlab/nginx/conf/gitlab-mattermost-http.conf'
        'registry-nginx' | '/var/opt/gitlab/nginx/conf/gitlab-registry.conf'
      end

      with_them do
        it 'redirects http to https' do
          expect(node['gitlab'][redirect_config_key]['redirect_http_to_https']).to be_truthy
        end

        it 'includes the well known acme challenge location block' do
          expect(chef_run).to render_file(nginx_config_file).with_content { |content|
            https_redirect_server = content.match(https_redirect_block)
            https_server = content.match(https_block)

            expect(https_redirect_server).not_to be_nil
            expect(https_server).not_to be_nil

            expect(https_redirect_server.to_s).to match(acme_challenge_block)
            expect(https_server.to_s).to match(acme_challenge_block)
          }
        end
      end
    end

    it 'uses http authorization by default' do
      expect(chef_run).to include_recipe('letsencrypt::http_authorization')
    end

    it 'creates a self signed certificate' do
      expect(chef_run).to create_acme_selfsigned('fakehost.example.com').with(
        key: '/etc/gitlab/ssl/fakehost.example.com.key',
        crt: '/etc/gitlab/ssl/fakehost.example.com.crt'
      )
    end

    it 'creates a letsencrypt certificate' do
      expect(chef_run).to create_letsencrypt_certificate('fakehost.example.com').with(
        key: '/etc/gitlab/ssl/fakehost.example.com.key',
        crt: '/etc/gitlab/ssl/fakehost.example.com.crt'
      )
    end

    it 'warns the user' do
      prod_cert = chef_run.letsencrypt_certificate('fakehost.example.com')
      expect(prod_cert).to notify('ruby_block[display_le_message]').to(:run)
    end

    context 'auto_renew' do
      context 'default' do
        it 'enables crond' do
          expect(chef_run).to include_recipe('crond::enable')
        end

        it 'adds a crond_job' do
          expect(chef_run).to create_crond_job('letsencrypt-renew').with(
            user: "root",
            hour: 0,
            minute: 31,
            day_of_month: "*/4",
            command: "/opt/gitlab/bin/gitlab-ctl renew-le-certs"
          )
        end

        it 'does not log a warning' do
          expect(LoggingHelper).not_to receive(:warning).with("Let's Encrypt is enabled, but external_url is using http")
          chef_run.ruby_block('display_le_message').block.call
        end
      end

      context 'false' do
        before do
          stub_gitlab_rb(letsencrypt: { enable: true, auto_renew: false })
          allow_any_instance_of(PgHelper).to receive(:is_standby?).and_return false
        end

        it 'removes the letsencrypt-renew cronjob' do
          expect(chef_run).to delete_crond_job('letsencrypt-renew')
        end

        it 'warns that we do not setup automatic renewal' do
          chef_run.ruby_block('display_le_message').block.call

          expect_logged_warning(/does not setup/)
        end
      end
    end

    context 'external_url uses http' do
      before do
        stub_gitlab_rb(
          external_url: 'http://plainhost.example.com',
          letsencrypt: {
            enable: true
          }
        )
      end

      it 'logs a warning' do
        expect(chef_run).to run_ruby_block('http external-url')
      end
    end
  end
end

# This should work standalone for renewal purposes
RSpec.describe 'letsencrypt::renew' do
  let(:chef_run) do
    ChefSpec::SoloRunner.converge('gitlab::letsencrypt_renew')
  end

  before do
    allow_any_instance_of(OmnibusHelper).to receive(:service_up?).and_return(false)
    allow_any_instance_of(OmnibusHelper).to receive(:service_up?).with('nginx').and_return(true)
  end

  context 'letsencrypt enabled' do
    before do
      allow(Gitlab).to receive(:[]).and_call_original
      stub_gitlab_rb(
        external_url: 'https://standalone.fakehost.com',
        letsencrypt: {
          enable: true
        }
      )
    end

    it 'executes letsencrypt_certificate' do
      expect(chef_run).to create_letsencrypt_certificate('standalone.fakehost.com')
    end
  end

  context 'letsencrypt auto-enabled' do
    before do
      allow(Gitlab).to receive(:[]).and_call_original
      allow(OpenSSL::X509::Certificate).to receive(:not_after).and_return(Time.now - 1)
      stub_gitlab_rb(
        external_url: 'https://standalone.fakehost.com'
      )
    end

    it 'executes letsencrypt_certificate' do
      expect(chef_run).to create_letsencrypt_certificate('standalone.fakehost.com')
    end
  end
end
