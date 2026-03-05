require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'Gitaly settings' do
    context 'with default values' do
      it 'renders gitlab.yml without Gitaly token set' do
        expect(gitlab_yml[:production][:gitaly]).to eq(
          client_max_attempts: 4,
          client_max_backoff: '1.4s',
          client_path: "/opt/gitlab/embedded/bin",
          token: ""
        )
      end
    end

    context 'with user specified token' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            gitaly_token: 'token123456'
          }
        )
      end

      it 'renders gitlab.yml with user specified token' do
        expect(gitlab_yml[:production][:gitaly]).to eq(
          client_max_attempts: 4,
          client_max_backoff: '1.4s',
          client_path: "/opt/gitlab/embedded/bin",
          token: 'token123456'
        )
      end
    end

    context 'with both gitlab_rails and gitaly_client options set' do
      before do
        stub_gitlab_rb(
          gitaly_client: {
            max_attempts: 2,
            max_backoff: '0.5s'
          },
          gitlab_rails: {
            gitaly_client_max_attempts: 5,
            gitaly_client_max_backoff: '2.0s'
          }
        )
      end

      it 'renders gitlab.yml with gitlab_rails settings taking precedence' do
        expect(gitlab_yml[:production][:gitaly]).to eq(
          client_max_attempts: 5,
          client_max_backoff: '2.0s',
          client_path: "/opt/gitlab/embedded/bin",
          token: ""
        )
      end
    end
  end
end
