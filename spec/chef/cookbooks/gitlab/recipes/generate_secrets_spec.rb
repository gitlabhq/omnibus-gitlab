# These tests confirm that calling the generate_secrets recipe works correctly
# both when using the default path and and when using anoptional path to the
# secrets file. It tests that the file is created and contains secrets. It does
# not exhaustively test the resulting secrets file contents. Those tests are
# left to secrets_helper_spec.rb.

require 'chef_helper'
require_relative '../../../../../files/gitlab-cookbooks/package/libraries/helpers/secrets_helper'

RSpec.describe 'generate_secrets' do
  let(:chef_runner) { ChefSpec::SoloRunner.new }
  let(:chef_run) { chef_runner.converge('gitlab::generate_secrets') }
  let(:node) { chef_runner.node }

  optional_path = '/etc/mygitlab/mysecrets.json'.freeze
  hex_key = /\h{128}/.freeze
  rsa_key = /\A-----BEGIN RSA PRIVATE KEY-----\n.+\n-----END RSA PRIVATE KEY-----\n\Z/m.freeze
  default_secrets_error_regexp = %r{You have enabled writing to the default secrets file location with package\['generate_secrets_json_file'].*}

  def stub_gitlab_secrets_json(secrets)
    allow(File).to receive(:read).with(SecretsHelper::SECRETS_FILE).and_return(JSON.generate(secrets))
  end

  def stub_check_secrets
    rails_keys = new_secrets['gitlab_rails']
    hex_keys = rails_keys.values_at('db_key_base', 'otp_key_base', 'secret_key_base', 'encrypted_settings_key_base')
    rsa_keys = rails_keys.values_at('openid_connect_signing_key', 'ci_jwt_signing_key')

    expect(rails_keys.to_a.uniq).to eq(rails_keys.to_a)
    expect(hex_keys).to all(match(hex_key))
    expect(rsa_keys).to all(match(rsa_key))
  end

  before do
    allow(File).to receive(:directory?).and_call_original
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:open).and_call_original
  end

  context 'when default directory does not exist' do
    it 'does not write secrets to the file' do
      allow(File).to receive(:directory?).with(File.dirname(SecretsHelper::SECRETS_FILE)).and_return(false)
      expect(File).not_to receive(:open).with(SecretsHelper::SECRETS_FILE, 'w')

      chef_run
    end
  end

  context 'when optional path directory does not exist' do
    it 'does not write secrets to the file' do
      allow(File).to receive(:directory?).with(File.dirname(optional_path)).and_return(false)
      expect(File).not_to receive(:open).with(optional_path, 'w')

      node.normal[SecretsHelper::SECRETS_FILE_CHEF_ATTR] = optional_path
      chef_run
    end
  end

  context 'when optional path directory does exists and we request the optional secret path' do
    let(:file) { double(:file) }
    let(:new_secrets) { @new_secrets }
    before do
      allow(SecretsHelper).to receive(:system)
      allow(File).to receive(:directory?).with(File.dirname(optional_path)).and_return(true)

      allow(file).to receive(:puts) { |json| @new_secrets = JSON.parse(json) }
      allow(file).to receive(:chmod).and_return(true)
    end

    context 'when there are no existing secrets and generate_secrets_json_file = false' do
      before do
        allow(File).to receive(:open).with(optional_path, 'w', 0600).and_yield(file).once

        node.normal[SecretsHelper::SECRETS_FILE_CHEF_ATTR] = optional_path
        node.normal['package']['generate_secrets_json_file'] = false
        chef_run
      end

      it 'writes new secrets to the file, with different values for each' do
        rails_keys = new_secrets['gitlab_rails']
        hex_keys = rails_keys.values_at('db_key_base', 'otp_key_base', 'secret_key_base', 'encrypted_settings_key_base')
        rsa_keys = rails_keys.values_at('openid_connect_signing_key', 'ci_jwt_signing_key')

        expect(rails_keys.to_a.uniq).to eq(rails_keys.to_a)
        expect(hex_keys).to all(match(hex_key))
        expect(rsa_keys).to all(match(rsa_key))
      end
    end
  end

  context 'when there are no existing secrets and generate_secrets_json_file = true' do
    before do
      allow(File).to receive(:directory?).with(optional_path).and_return(false)
      allow(File).to receive(:exist?).with(File.dirname(optional_path)).and_return(true)
      node.normal[SecretsHelper::SECRETS_FILE_CHEF_ATTR] = optional_path
      node.normal['package']['generate_secrets_json_file'] = true
    end

    it 'does not write secrets to the file' do
      expect(File).not_to receive(:directory?).with(File.dirname(optional_path))
      expect(File).not_to receive(:open).with(optional_path, 'w')
      expect(LoggingHelper).to receive(:warning).with(default_secrets_error_regexp)

      chef_run
    end
  end

  context 'when there are no existing secrets and generate_secrets_json_file is not set' do
    before do
      allow(File).to receive(:directory?).with(optional_path).and_return(false)
      allow(File).to receive(:exist?).with(File.dirname(optional_path)).and_return(true)
      node.normal[SecretsHelper::SECRETS_FILE_CHEF_ATTR] = optional_path
    end

    it 'does not write secrets to the file' do
      expect(File).not_to receive(:directory?).with(File.dirname(optional_path))
      expect(File).not_to receive(:open).with(optional_path, 'w')
      expect(LoggingHelper).to receive(:warning).with(default_secrets_error_regexp)

      chef_run
    end
  end
end
