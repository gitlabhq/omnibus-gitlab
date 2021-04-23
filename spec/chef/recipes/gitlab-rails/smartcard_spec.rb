require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'Smartcard authentication settings' do
    context 'with default configuration' do
      it 'renders gitlab.yml with Smartcard authentication disabled' do
        expect(gitlab_yml[:production][:smartcard]).to eq(
          enabled: false,
          ca_file: '/etc/gitlab/ssl/CA.pem',
          client_certificate_required_host: nil,
          client_certificate_required_port: 3444,
          required_for_git_access: false,
          san_extensions: false
        )
      end
    end

    context 'with user specified configuration' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            smartcard_enabled: true,
            smartcard_ca_file: '/foobar/CA.pem',
            smartcard_client_certificate_required_host: 'smartcard.gitlab.example.com',
            smartcard_client_certificate_required_port: 123,
            smartcard_required_for_git_access: true,
            smartcard_san_extensions: true
          }
        )
      end

      it 'renders gitlab.yml with user specified values for Smartcard authentication' do
        expect(gitlab_yml[:production][:smartcard]).to eq(
          enabled: true,
          ca_file: '/foobar/CA.pem',
          client_certificate_required_host: 'smartcard.gitlab.example.com',
          client_certificate_required_port: 123,
          required_for_git_access: true,
          san_extensions: true
        )
      end
    end
  end
end
