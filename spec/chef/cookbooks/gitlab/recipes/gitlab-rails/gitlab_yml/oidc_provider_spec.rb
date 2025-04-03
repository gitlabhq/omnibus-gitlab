require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'OIDC provider settings' do
    context 'with default values' do
      it 'does not render in gitlab.yml' do
        expect(gitlab_yml[:production][:oidc_provider]).to be nil
      end
    end

    context 'with user specified values' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            oidc_provider_openid_id_token_expire_in_seconds: 120
          }
        )
      end

      it 'renders gitlab.yml with specified value for ID token duration' do
        expect(gitlab_yml[:production][:oidc_provider][:openid_id_token_expire_in_seconds]).to eq(120)
      end
    end
  end
end
