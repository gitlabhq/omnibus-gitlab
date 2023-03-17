require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  using RSpec::Parameterized::TableSyntax
  include_context 'gitlab-rails'

  describe 'DuoAuth settings' do
    context 'with default values' do
      it 'renders gitlab.yml with duo auth disabled' do
        expect(gitlab_yml[:production][:duo_auth]).to eq(
          enabled: false
        )
      end
    end

    context 'with user specified values' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            duo_auth_enabled: true,
            duo_auth_hostname: 'duo_auth.example.com',
            duo_auth_integration_key: '1nt3gr4tionKey',
            duo_auth_secret_key: '123e4et',
          }
        )
      end

      it 'renders gitlab.yml with user specified values' do
        expect(gitlab_yml[:production][:duo_auth]).to eq(
          enabled: true,
          hostname: 'duo_auth.example.com',
          integration_key: '1nt3gr4tionKey',
          secret_key: '123e4et'
        )
      end
    end
  end
end
