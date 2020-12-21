require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'sentry settings' do
    context 'with default values' do
      it 'renders gitlab.yml with sentry disabled' do
        expect(gitlab_yml[:production][:sentry]).to eq(
          {
            enabled: false,
            dsn: nil,
            clientside_dsn: nil,
            environment: nil
          }
        )
      end
    end

    context 'when the user enables sentry' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            sentry_enabled: true,
            sentry_dsn: 'https://708cd0ca88972f04d5c836a395b8db63@example.com/76',
            sentry_clientside_dsn: 'https://708cd0ca88972f04d5c836a395b8db63@example.com/77',
            sentry_environment: 'testing'
          }
        )
      end

      it 'renders gitlab.yml with user specified values' do
        expect(gitlab_yml[:production][:sentry]).to eq(
          {
            enabled: true,
            dsn: 'https://708cd0ca88972f04d5c836a395b8db63@example.com/76',
            clientside_dsn: 'https://708cd0ca88972f04d5c836a395b8db63@example.com/77',
            environment: 'testing'
          }
        )
      end
    end
  end
end
