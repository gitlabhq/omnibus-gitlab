require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'Microsoft Graph Mailer settings' do
    context 'with default configuration' do
      it 'renders gitlab.yml with Microsoft Graph Mailer disabled' do
        expect(gitlab_yml[:production][:microsoft_graph_mailer]).to eq(
          enabled: false,
          user_id: nil,
          tenant: nil,
          client_id: nil,
          client_secret: nil,
          azure_ad_endpoint: nil,
          graph_endpoint: nil
        )
      end
    end

    context 'with user specified configuration' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            microsoft_graph_mailer_enabled: true,
            microsoft_graph_mailer_user_id: 'YOUR-USER-ID',
            microsoft_graph_mailer_tenant: 'YOUR-TENANT-ID',
            microsoft_graph_mailer_client_id: 'YOUR-CLIENT-ID',
            microsoft_graph_mailer_client_secret: 'YOUR-CLIENT-SECRET-ID',
            microsoft_graph_mailer_azure_ad_endpoint: 'https://login.microsoftonline.com',
            microsoft_graph_mailer_graph_endpoint: 'https://graph.microsoft.com'
          }
        )
      end

      it 'renders gitlab.yml with user specified values for Microsoft Graph Mailer' do
        expect(gitlab_yml[:production][:microsoft_graph_mailer]).to eq(
          enabled: true,
          user_id: 'YOUR-USER-ID',
          tenant: 'YOUR-TENANT-ID',
          client_id: 'YOUR-CLIENT-ID',
          client_secret: 'YOUR-CLIENT-SECRET-ID',
          azure_ad_endpoint: 'https://login.microsoftonline.com',
          graph_endpoint: 'https://graph.microsoft.com'
        )
      end
    end
  end
end
