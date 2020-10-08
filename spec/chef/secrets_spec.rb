require 'chef_helper'
require 'base64'

RSpec.describe 'secrets' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge('gitlab::default') }

  HEX_KEY = /\h{128}/.freeze
  RSA_KEY = /\A-----BEGIN RSA PRIVATE KEY-----\n.+\n-----END RSA PRIVATE KEY-----\n\Z/m.freeze

  def stub_gitlab_secrets_json(secrets)
    allow(File).to receive(:read).with('/etc/gitlab/gitlab-secrets.json').and_return(JSON.generate(secrets))
  end

  before do
    allow(File).to receive(:directory?).and_call_original
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:open).and_call_original
  end

  context 'when /etc/gitlab does not exist' do
    it 'does not write secrets to the file' do
      allow(File).to receive(:directory?).with('/etc/gitlab').and_return(false)
      expect(File).not_to receive(:open).with('/etc/gitlab/gitlab-secrets.json', 'w')

      chef_run
    end
  end

  context 'when /etc/gitlab exists' do
    let(:file) { double(:file) }
    let(:new_secrets) { @new_secrets }
    let(:gitlab_rb_ci_jwt_signing_key) { SecretsHelper.generate_rsa(4096).to_pem }

    before do
      allow(SecretsHelper).to receive(:system)
      allow(File).to receive(:directory?).with('/etc/gitlab').and_return(true)
      allow(File).to receive(:open).with('/etc/gitlab/gitlab-secrets.json', 'w', 0600).and_yield(file).once
      allow(file).to receive(:puts) { |json| @new_secrets = JSON.parse(json) }
      allow(file).to receive(:chmod).and_return(true)
    end

    context 'when there are no existing secrets' do
      before do
        allow(File).to receive(:exist?).with('/etc/gitlab/gitlab-secrets.json').and_return(false)

        chef_run
      end

      it 'writes new secrets to the file, with different values for each' do
        rails_keys = new_secrets['gitlab_rails']
        hex_keys = rails_keys.values_at('db_key_base', 'otp_key_base', 'secret_key_base')
        rsa_keys = rails_keys.values_at('openid_connect_signing_key', 'ci_jwt_signing_key')

        expect(rails_keys.to_a.uniq).to eq(rails_keys.to_a)
        expect(hex_keys).to all(match(HEX_KEY))
        expect(rsa_keys).to all(match(RSA_KEY))
      end

      it 'does not write legacy keys' do
        expect(new_secrets).not_to have_key('gitlab_ci')
        expect(new_secrets['gitlab_rails']).not_to have_key('jws_private_key')
      end

      it 'generates an appropriate secret for gitlab-workhorse' do
        workhorse_secret = new_secrets['gitlab_workhorse']['secret_token']
        expect(Base64.strict_decode64(workhorse_secret).length).to eq(32)
      end

      it 'generates an appropriate shared secret for gitlab-pages' do
        pages_shared_secret = new_secrets['gitlab_pages']['api_secret_key']
        expect(Base64.strict_decode64(pages_shared_secret).length).to eq(32)
      end

      it 'generates an appropriate shared secret for gitlab-kas' do
        kas_shared_secret = new_secrets['gitlab_kas']['api_secret_key']
        expect(Base64.strict_decode64(kas_shared_secret).length).to eq(32)
      end
    end

    context 'gitlab.rb provided gitlab_pages.api_secret_key' do
      before do
        allow(Gitlab).to receive(:[]).and_call_original
      end

      it 'fails when provided gitlab_pages.shared_secret is not 32 bytes' do
        stub_gitlab_rb(gitlab_pages: { api_secret_key: SecureRandom.base64(16) })

        expect { chef_run }.to raise_error(RuntimeError, /gitlab_pages\['api_secret_key'\] should be exactly 32 bytes/)
      end

      it 'accepts provided gitlab_pages.api_secret_key when it is 32 bytes' do
        api_secret_key = SecureRandom.base64(32)
        stub_gitlab_rb(gitlab_pages: { api_secret_key: api_secret_key })

        expect { chef_run }.not_to raise_error
        expect(new_secrets['gitlab_pages']['api_secret_key']).to eq(api_secret_key)
      end
    end

    context 'gitlab.rb provided gitlab_kas.api_secret_key' do
      before do
        allow(Gitlab).to receive(:[]).and_call_original
      end

      it 'fails when provided gitlab_kas.shared_secret is not 32 bytes' do
        stub_gitlab_rb(gitlab_kas: { api_secret_key: SecureRandom.base64(16) })

        expect { chef_run }.to raise_error(RuntimeError, /gitlab_kas\['api_secret_key'\] should be exactly 32 bytes/)
      end

      it 'accepts provided gitlab_kas.api_secret_key when it is 32 bytes' do
        api_secret_key = SecureRandom.base64(32)
        stub_gitlab_rb(gitlab_kas: { api_secret_key: api_secret_key })

        expect { chef_run }.not_to raise_error
        expect(new_secrets['gitlab_kas']['api_secret_key']).to eq(api_secret_key)
      end
    end

    context 'when there are existing secrets in /etc/gitlab/gitlab-secrets.json' do
      before do
        allow(SecretsHelper).to receive(:system)
        allow(File).to receive(:directory?).with('/etc/gitlab').and_return(true)
        allow(File).to receive(:open).with('/etc/gitlab/gitlab-secrets.json', 'w').and_yield(file).once
        allow(File).to receive(:exist?).with('/etc/gitlab/gitlab-secrets.json').and_return(true)
      end

      context 'when secrets are only partially present' do
        before do
          stub_gitlab_secrets_json(gitlab_ci: { db_key_base: 'json_ci_db_key_base' })
          chef_run
        end

        it 'uses secrets from /etc/gitlab/gitlab-secrets.json where available' do
          expect(new_secrets['gitlab_rails']['db_key_base']).to eq('json_ci_db_key_base')
        end

        it 'falls back further to generating new secrets' do
          expect(new_secrets['gitlab_rails']['otp_key_base']).to match(HEX_KEY)
        end
      end

      context 'when secrets exist under legacy keys' do
        before do
          stub_gitlab_secrets_json(
            gitlab_ci: { db_key_base: 'json_ci_db_key_base', secret_token: 'json_ci_secret_token' },
            gitlab_rails: {
              secret_token: 'json_rails_secret_token',
              jws_private_key: 'json_rails_jws_private_key'
            }
          )

          chef_run
        end

        it 'moves gitlab_ci.db_key_base to gitlab_rails.db_key_base' do
          expect(new_secrets['gitlab_rails']['db_key_base']).to eq('json_ci_db_key_base')
        end

        it 'moves gitlab_rails.secret_token to gitlab_rails.otp_key_base' do
          expect(new_secrets['gitlab_rails']['otp_key_base']).to eq('json_rails_secret_token')
        end

        it 'moves gitlab_ci.db_key_base to gitlab_rails.secret_key_base' do
          expect(new_secrets['gitlab_rails']['secret_key_base']).to eq('json_ci_db_key_base')
        end

        it 'moves gitlab_rails.jws_private_key to gitlab_rails.openid_connect_signing_key' do
          expect(new_secrets['gitlab_rails']['openid_connect_signing_key']).to eq('json_rails_jws_private_key')
        end

        it 'ignores other, unused, secrets' do
          expect(new_secrets.inspect).not_to include('json_ci_secret_token')
        end
      end
    end

    context 'when there are existing secrets in /etc/gitlab/gitlab.rb and /etc/gitlab/gitlab-secrets.json' do
      before do
        allow(Gitlab).to receive(:[]).and_call_original
        allow(File).to receive(:exist?).with('/etc/gitlab/gitlab-secrets.json').and_return(true)
      end

      context 'when secrets are only partially present' do
        before do
          stub_gitlab_secrets_json(
            gitlab_ci: { db_key_base: 'json_ci_db_key_base' },
            gitlab_rails: {
              secret_token: 'json_rails_secret_token',
              jws_private_key: 'json_rails_jws_private_key'
            }
          )

          stub_gitlab_rb(gitlab_ci: { db_key_base: 'rb_ci_db_key_base' })

          chef_run
        end

        it 'uses secrets from /etc/gitlab/gitlab.rb when available' do
          expect(new_secrets['gitlab_rails']['db_key_base']).to eq('rb_ci_db_key_base')
        end

        it 'falls back to secrets from /etc/gitlab/gitlab-secrets.json' do
          expect(new_secrets['gitlab_rails']['otp_key_base']).to eq('json_rails_secret_token')
        end

        it 'falls back further to generating new secrets' do
          expect(new_secrets['gitlab_shell']['secret_token']).to match(HEX_KEY)
        end
      end

      context 'when secrets exist under legacy keys' do
        before do
          stub_gitlab_rb(gitlab_ci: { db_key_base: 'rb_ci_db_key_base',
                                      secret_token: 'rb_ci_secret_token' })

          stub_gitlab_secrets_json(
            gitlab_rails: {
              secret_token: 'json_rails_secret_token',
              jws_private_key: 'json_rails_jws_private_key',
              ci_jwt_signing_key: gitlab_rb_ci_jwt_signing_key
            }
          )

          chef_run
        end

        it 'moves gitlab_ci.db_key_base to gitlab_rails.db_key_base' do
          expect(new_secrets['gitlab_rails']['db_key_base']).to eq('rb_ci_db_key_base')
        end

        it 'moves gitlab_rails.secret_token to gitlab_rails.otp_key_base' do
          expect(new_secrets['gitlab_rails']['otp_key_base']).to eq('json_rails_secret_token')
        end

        it 'moves gitlab_ci.db_key_base to gitlab_rails.secret_key_base' do
          expect(new_secrets['gitlab_rails']['secret_key_base']).to eq('rb_ci_db_key_base')
        end

        it 'moves gitlab_rails.jws_private_key to gitlab_rails.openid_connect_signing_key' do
          expect(new_secrets['gitlab_rails']['openid_connect_signing_key']).to eq('json_rails_jws_private_key')
        end

        it 'ignores other, unused, secrets' do
          expect(new_secrets.inspect).not_to include('rb_ci_secret_token')
        end

        it 'writes the correct data to secrets.yml' do
          expect(chef_run).to create_templatesymlink('Create a secrets.yml and create a symlink to Rails root').with_variables(
            'secrets' => {
              'production' => {
                'db_key_base' => 'rb_ci_db_key_base',
                'secret_key_base' => 'rb_ci_db_key_base',
                'otp_key_base' => 'json_rails_secret_token',
                'openid_connect_signing_key' => 'json_rails_jws_private_key',
                'ci_jwt_signing_key' => gitlab_rb_ci_jwt_signing_key
              }
            }
          )
        end

        it 'deletes the secret file' do
          expect(chef_run).to delete_file('/var/opt/gitlab/gitlab-rails/etc/secret')
          expect(chef_run).to delete_file('/opt/gitlab/embedded/service/gitlab-rails/.secret')
        end
      end

      context 'when secrets are ambiguous and cannot be migrated automatically' do
        before { stub_gitlab_secrets_json({}) }

        it 'fails when gitlab_ci.db_key_base and gitlab_rails.db_key_base are different' do
          stub_gitlab_rb(
            gitlab_rails: { db_key_base: 'rb_rails_db_key_base' },
            gitlab_ci: { db_key_base: 'rb_ci_db_key_base' }
          )

          expect(File).not_to receive(:open).with('/etc/gitlab/gitlab-secrets.json', 'w')
          expect { chef_run }.to raise_error(RuntimeError, /db_key_base/)
        end

        it 'fails when the secret file does not match gitlab_rails.otp_key_base' do
          secret_file = '/var/opt/gitlab/gitlab-rails/etc/secret'

          stub_gitlab_rb(gitlab_rails: { otp_key_base: 'rb_rails_otp_key_base',
                                         secret_key_base: 'rb_rails_secret_key_base' })

          allow(File).to receive(:exist?).with(secret_file).and_return(true)
          allow(File).to receive(:read).with(secret_file).and_return('secret_key_base')

          expect { chef_run }.to raise_error(RuntimeError, /otp_key_base/)
        end
      end

      context 'ci_jwt_signing_key' do
        let(:secrets_json_ci_jwt_signing_key) { SecretsHelper.generate_rsa(4096).to_pem }

        it 'uses the key from /etc/gitlab/gitlab.rb when available' do
          stub_gitlab_secrets_json(
            gitlab_rails: { ci_jwt_signing_key: secrets_json_ci_jwt_signing_key }
          )

          stub_gitlab_rb(
            gitlab_rails: { ci_jwt_signing_key: gitlab_rb_ci_jwt_signing_key }
          )

          chef_run

          expect(new_secrets['gitlab_rails']['ci_jwt_signing_key']).to eq(gitlab_rb_ci_jwt_signing_key)
        end

        it 'uses the key from /etc/gitlab/gitlab-secrets.json when available' do
          stub_gitlab_secrets_json(
            gitlab_rails: { ci_jwt_signing_key: secrets_json_ci_jwt_signing_key }
          )

          chef_run

          expect(new_secrets['gitlab_rails']['ci_jwt_signing_key']).to eq(secrets_json_ci_jwt_signing_key)
        end

        it 'rejects invalid RSA keys' do
          stub_gitlab_secrets_json({})
          stub_gitlab_rb(
            gitlab_rails: { ci_jwt_signing_key: 'invalid key' }
          )

          expect { chef_run }.to raise_error('ci_jwt_signing_key: The provided key is not valid RSA key')
        end

        it 'rejects RSA public keys' do
          public_key = SecretsHelper.generate_rsa(4096).public_key.to_pem

          stub_gitlab_secrets_json({})
          stub_gitlab_rb(
            gitlab_rails: { ci_jwt_signing_key: public_key }
          )

          expect { chef_run }.to raise_error('ci_jwt_signing_key: The provided key is not private RSA key')
        end

        it 'writes the correct data to secrets.yml' do
          stub_gitlab_secrets_json({})

          stub_gitlab_rb(
            gitlab_rails: {
              db_key_base: 'rb_ci_db_key_base',
              secret_key_base: 'rb_ci_db_key_base',
              otp_key_base: 'json_rails_secret_token',
              openid_connect_signing_key: 'json_rails_jws_private_key',
              ci_jwt_signing_key: gitlab_rb_ci_jwt_signing_key
            }
          )

          expect(chef_run).to create_templatesymlink('Create a secrets.yml and create a symlink to Rails root').with_variables(
            'secrets' => {
              'production' => {
                'db_key_base' => 'rb_ci_db_key_base',
                'secret_key_base' => 'rb_ci_db_key_base',
                'otp_key_base' => 'json_rails_secret_token',
                'openid_connect_signing_key' => 'json_rails_jws_private_key',
                'ci_jwt_signing_key' => gitlab_rb_ci_jwt_signing_key
              }
            }
          )
        end
      end
    end
  end
end
