require 'chef_helper'

RSpec.describe AuthorizeHelper do
  # AuthorizeHelper is a plain module; mix it into a test class
  let(:helper) do
    Class.new do
      include AuthorizeHelper

      def execute_rails_runner(cmd)
        cmd
      end

      def do_shell_out(cmd)
        cmd
      end

      def warn(_msg)
        nil
      end
    end.new
  end

  describe 'DEFAULT_ORGANIZATION_ID' do
    it 'is set to 1' do
      expect(described_class::DEFAULT_ORGANIZATION_ID).to eq(1)
    end
  end

  describe '#create_or_find_authorization' do
    let(:uri) { 'http://localhost/callback' }
    let(:name) { 'GitLab Pages' }
    let(:oauth_uid) { 'test-uid' }
    let(:oauth_secret) { 'test-secret' }

    subject(:result) do
      helper.create_or_find_authorization(uri, name, oauth_uid, oauth_secret)
    end

    it 'includes organization_id in the create! call' do
      expect(result).to include(
        "organization_id: #{AuthorizeHelper::DEFAULT_ORGANIZATION_ID}"
      )
    end

    it 'includes the redirect_uri in the create! call' do
      expect(result).to include(%(redirect_uri: "#{uri}"))
    end

    it 'includes the name in the create! call' do
      expect(result).to include(%(name: "#{name}"))
    end

    it 'includes the uid in the create! call' do
      expect(result).to include(%(uid: "#{oauth_uid}"))
    end

    it 'includes the secret in the create! call' do
      expect(result).to include(%(secret: "#{oauth_secret}"))
    end

    it 'uses Authn::OauthApplication, not Doorkeeper::Application' do
      expect(result).to include('Authn::OauthApplication')
      expect(result).not_to include('Doorkeeper::Application')
    end

    it 'falls back to create! after by_uid_and_secret lookup' do
      expect(result).to include('by_uid_and_secret')
    end

    it 'backfills organization_id on existing apps with nil organization_id' do
      expect(result).to include('update_column(:organization_id')
      expect(result).to include('organization_id.nil?')
    end

    it 'outputs the app uid and secret' do
      expect(result).to include(
        'puts app.uid.concat(" ").concat(app.secret)'
      )
    end
  end
end
