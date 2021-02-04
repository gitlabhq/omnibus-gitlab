require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  using RSpec::Parameterized::TableSyntax
  include_context 'gitlab-rails'

  describe 'Unleash settings' do
    context 'with default values' do
      it 'renders gitlab.yml unleash disabled' do
        expect(gitlab_yml[:production][:feature_flags][:unleash]).to eq(
          enabled: false
        )
      end
    end

    context 'with user specified values' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            feature_flags_unleash_enabled: true,
            feature_flags_unleash_url: 'foobar.com',
            feature_flags_unleash_app_name: 'GitLab Production',
            feature_flags_unleash_instance_id: 'foobar'
          }
        )
      end

      it 'renders gitlab.yml with user specified values' do
        expect(gitlab_yml[:production][:feature_flags][:unleash]).to eq(
          enabled: true,
          url: 'foobar.com',
          app_name: 'GitLab Production',
          instance_id: 'foobar'
        )
      end
    end
  end
end
