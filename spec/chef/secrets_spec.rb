require 'chef_helper'
require 'base64'

describe 'secrets' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default') }

  def stub_gitlab_secrets_json(secrets)
    allow(File).to receive(:read).with('/etc/gitlab/gitlab-secrets.json').and_return(JSON.generate(secrets))
  end

  before do
    allow(File).to receive(:directory?).and_call_original
    allow(File).to receive(:exists?).and_call_original
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

    before do
      allow(SecretsHelper).to receive(:system)
      allow(File).to receive(:directory?).with('/etc/gitlab').and_return(true)
      allow(File).to receive(:open).with('/etc/gitlab/gitlab-secrets.json', 'w', 0600).and_yield(file).once
      allow(file).to receive(:puts) { |json| @new_secrets = JSON.parse(json) }
      allow(file).to receive(:chmod).and_return(true)
    end

    context 'when there are no existing secrets' do
      before do
        allow(File).to receive(:exists?).with('/etc/gitlab/gitlab-secrets.json').and_return(false)

        chef_run
      end

      it 'writes new secrets to the file, with different values for each' do
        rails_keys = new_secrets['gitlab_rails'].values_at('db_key_base', 'otp_key_base', 'secret_key_base')

        expect(rails_keys).to all(match(/\h{128}/))
        expect(rails_keys.uniq).to eq(rails_keys)
      end

      it 'does not write legacy keys' do
        expect(new_secrets).not_to have_key('gitlab_ci')
      end

      it 'generates an appropriate secret for gitlab-workhorse' do
        workhorse_secret = new_secrets['gitlab_workhorse']['secret_token']
        expect(Base64.strict_decode64(workhorse_secret).length).to eq(32)
      end
    end

    context 'when there are existing secrets in /etc/gitlab/gitlab-secrets.json' do
      before do
        allow(SecretsHelper).to receive(:system)
        allow(File).to receive(:directory?).with('/etc/gitlab').and_return(true)
        allow(File).to receive(:open).with('/etc/gitlab/gitlab-secrets.json', 'w').and_yield(file).once
        allow(File).to receive(:exists?).with('/etc/gitlab/gitlab-secrets.json').and_return(true)
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
          expect(new_secrets['gitlab_rails']['otp_key_base']).to match(/\h{128}/)
        end
      end

      context 'when secrets exist under legacy keys' do
        before do
          stub_gitlab_secrets_json(
            gitlab_ci: { db_key_base: 'json_ci_db_key_base', secret_token: 'json_ci_secret_token' },
            gitlab_rails: { secret_token: 'json_rails_secret_token' }
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

        it 'ignores other, unused, secrets' do
          expect(new_secrets.inspect).not_to include('json_ci_secret_token')
        end
      end
    end

    context 'when there are existing secrets in /etc/gitlab/gitlab.rb and /etc/gitlab/gitlab-secrets.json' do
      before do
        allow(Gitlab).to receive(:[]).and_call_original
        allow(File).to receive(:exists?).with('/etc/gitlab/gitlab-secrets.json').and_return(true)
      end

      context 'when secrets are only partially present' do
        before do
          stub_gitlab_secrets_json(
            gitlab_ci: { db_key_base: 'json_ci_db_key_base' },
            gitlab_rails: { secret_token: 'json_rails_secret_token' }
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
          expect(new_secrets['gitlab_shell']['secret_token']).to match(/\h{128}/)
        end
      end

      context 'when secrets exist under legacy keys' do
        before do
          stub_gitlab_rb(gitlab_ci: { db_key_base: 'rb_ci_db_key_base',
                                      secret_token: 'rb_ci_secret_token' })

          stub_gitlab_secrets_json(gitlab_rails: { secret_token: 'json_rails_secret_token' })
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

        it 'ignores other, unused, secrets' do
          expect(new_secrets.inspect).not_to include('rb_ci_secret_token')
        end

        it 'writes the correct data to secrets.yml' do
          yaml_secrets = lambda do |yaml|
            secrets = YAML.load(yaml)['production']

            expect(secrets).to include('db_key_base' => 'rb_ci_db_key_base')
            expect(secrets).to include('otp_key_base' => 'json_rails_secret_token')
            expect(secrets).to include('secret_key_base' => 'rb_ci_db_key_base')
          end

          expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/secrets.yml').with_content(&yaml_secrets)
        end

        it 'deletes the secret file' do
          expect(chef_run).to delete_file('/var/opt/gitlab/gitlab-rails/etc/secret')
          expect(chef_run).to delete_file('/opt/gitlab/embedded/service/gitlab-rails/.secret')
        end
      end

      context 'when there is a legacy CI gitlab_server key' do
        before do
          stub_gitlab_secrets_json(gitlab_ci: { gitlab_server: { url: 'json_ci_gitlab_server' } })
          allow_any_instance_of(Object).to receive(:warn)
        end

        it 'warns that this value is no longer used, and prints the value' do
          expect_any_instance_of(Object).to receive(:warn) do |value|
            expect(value).to include('gitlab_server')
            expect(value).to include('json_ci_gitlab_server')
          end

          chef_run
        end

        it 'does not write the value to the new file' do
          chef_run

          expect(new_secrets).not_to have_key('gitlab_ci')
          expect(new_secrets.to_json).not_to include('json_ci_gitlab_server')
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

          allow(File).to receive(:exists?).with(secret_file).and_return(true)
          allow(File).to receive(:read).with(secret_file).and_return('secret_key_base')

          expect { chef_run }.to raise_error(RuntimeError, /otp_key_base/)
        end
      end
    end
  end
end
