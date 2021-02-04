require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  using RSpec::Parameterized::TableSyntax
  include_context 'gitlab-rails'

  describe 'FortiAuthenticator settings' do
    context 'with default values' do
      it 'renders gitlab.yml with FortiAuthenticator disabled' do
        expect(gitlab_yml[:production][:forti_authenticator]).to eq(
          enabled: false
        )
      end
    end

    context 'with user specified values' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            forti_authenticator_enabled: true,
            forti_authenticator_host: 'forti_authenticator.example.com',
            forti_authenticator_port: 444,
            forti_authenticator_username: 'janedoe',
            forti_authenticator_access_token: '123s3cr3t456'
          }
        )
      end

      it 'renders gitlab.yml with user specified values' do
        expect(gitlab_yml[:production][:forti_authenticator]).to eq(
          enabled: true,
          host: 'forti_authenticator.example.com',
          port: 444,
          username: 'janedoe',
          access_token: '123s3cr3t456'
        )
      end
    end
  end
end
