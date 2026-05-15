require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  using RSpec::Parameterized::TableSyntax
  include_context 'gitlab-rails'

  describe 'Mattermost settings' do
    context 'with default values' do
      it 'renders gitlab.yml with Mattermost disabled' do
        expect(gitlab_yml[:production][:mattermost]).to eq(
          enabled: false,
          host: nil
        )
      end
    end

    context 'with user specified values' do
      context 'when mattermost_external_url is specified' do
        before do
          stub_gitlab_rb(
            mattermost_external_url: 'http://mattermost.example.com'
          )
        end

        it 'renders gitlab.yml with specified Mattermost settings' do
          expect(gitlab_yml[:production][:mattermost]).to eq(
            enabled: true,
            host: 'http://mattermost.example.com'
          )
        end
      end

      context 'when mattermost is running on a different machine' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              mattermost_host: 'http://mattermost.example.com'
            }
          )
        end

        it 'renders gitlab.yml with specified Mattermost settings' do
          expect(gitlab_yml[:production][:mattermost]).to eq(
            enabled: true,
            host: 'http://mattermost.example.com'
          )
        end
      end

      context 'when both gitlab-rails.mattermost_host and mattermost_external_url is set' do
        before do
          stub_gitlab_rb(
            mattermost_external_url: 'http://foobar.com',
            gitlab_rails: {
              mattermost_host: 'http://mattermost.example.com'
            }
          )
        end

        it 'mattermost_external_url is used' do
          expect(gitlab_yml[:production][:mattermost][:host]).to eq('http://foobar.com')
        end
      end
    end
  end
end
