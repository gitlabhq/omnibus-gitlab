require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'Gitaly settings' do
    context 'with default values' do
      it 'renders gitlab.yml without Gitaly token set' do
        expect(gitlab_yml[:production][:gitaly]).to eq(
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
          client_path: "/opt/gitlab/embedded/bin",
          token: 'token123456'
        )
      end
    end
  end
end
