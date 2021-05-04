require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  using RSpec::Parameterized::TableSyntax
  include_context 'gitlab-rails'

  describe 'FortiToken Cloud settings' do
    context 'with default values' do
      it 'renders gitlab.yml with FortiAuthenticator disabled' do
        expect(gitlab_yml[:production][:forti_token_cloud]).to eq(
          enabled: false
        )
      end
    end

    context 'with user specified values' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            forti_token_cloud_enabled: true,
            forti_token_cloud_client_id: 'forti_token_cloud_client_id',
            forti_token_cloud_client_secret: '123s3cr3t456'
          }
        )
      end

      it 'renders gitlab.yml with user specified values' do
        expect(gitlab_yml[:production][:forti_token_cloud]).to eq(
          enabled: true,
          client_id: 'forti_token_cloud_client_id',
          client_secret: '123s3cr3t456'
        )
      end
    end
  end
end
