require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'OpenBao settings (for GitLab Secret Manager)' do
    context 'with default values' do
      it 'does not render in gitlab.yml' do
        expect(gitlab_yml[:production][:openbao]).to be nil
      end
    end

    context 'with a user defined url' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            openbao: {
              url: 'http://openbao.example.com'
            }
          }
        )
      end

      it 'renders gitlab.yml with specified URL' do
        expect(gitlab_yml[:production][:openbao][:url])
          .to eq('http://openbao.example.com')
      end
    end

    context 'with a user defined internal url' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            openbao: {
              url: 'http://openbao.example.com',
              internal_url: 'http://internal.openbao.example.com'
            }
          }
        )
      end

      it 'renders gitlab.yml with specified URL' do
        expect(gitlab_yml[:production][:openbao][:url])
          .to eq('http://openbao.example.com')
        expect(gitlab_yml[:production][:openbao][:internal_url])
          .to eq('http://internal.openbao.example.com')
      end
    end

    context 'with a user defined authentication_token_secret_file_path' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            openbao: {
              url: 'http://openbao.example.com',
              authentication_token_secret_file_path: '/path/to/authentication_token_secret_file'
            }
          }
        )
      end

      it 'renders gitlab.yml with specified authentication_token_secret_file_path' do
        expect(gitlab_yml[:production][:openbao][:authentication_token_secret_file_path])
          .to eq('/path/to/authentication_token_secret_file')
      end
    end
  end
end
