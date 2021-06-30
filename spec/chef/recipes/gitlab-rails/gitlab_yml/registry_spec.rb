require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'Registry settings' do
    context 'with default configuration' do
      context 'when GitLab is running under http' do
        it 'renders gitlab.yml without Registry settings' do
          expect(gitlab_yml[:production][:registry]).to eq(
            enabled: false,
            api_url: nil,
            host: nil,
            port: nil,
            issuer: 'omnibus-gitlab-issuer',
            key: '/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key',
            notification_secret: nil,
            path: nil
          )
        end
      end

      context 'when GitLab is running under HTTPS using Omnibus automated TLS certificates' do
        before do
          stub_gitlab_rb(
            external_url: 'https://gitlab.example.com'
          )
        end

        it 'automatically enables Registry and renders gitlab.yml accordingly' do
          expect(gitlab_yml[:production][:registry]).to eq(
            enabled: true,
            host: 'gitlab.example.com',
            port: 5050,
            api_url: 'http://localhost:5000',
            issuer: 'omnibus-gitlab-issuer',
            key: '/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key',
            notification_secret: nil,
            path: '/var/opt/gitlab/gitlab-rails/shared/registry'
          )
        end
      end

      context 'with user specified configuration' do
        context 'when URL for bundled Registry is specified' do
          before do
            stub_gitlab_rb(
              registry_external_url: 'http://registry.example.com'
            )
          end

          it 'renders gitlab.yml with specified Registry URL and other default Registry settings' do
            expect(gitlab_yml[:production][:registry]).to eq(
              enabled: true,
              host: 'registry.example.com',
              port: nil,
              api_url: 'http://localhost:5000',
              issuer: 'omnibus-gitlab-issuer',
              key: '/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key',
              notification_secret: nil,
              path: '/var/opt/gitlab/gitlab-rails/shared/registry'
            )
          end
        end

        context 'when other Registry configuration are specified' do
          before do
            stub_gitlab_rb(
              registry_external_url: 'http://registry.example.com:1234',
              registry: {
                registry_http_addr: 'localhost:1111'
              }
            )
          end

          it 'renders gitlab.yml with specified Registry settings' do
            expect(gitlab_yml[:production][:registry]).to eq(
              enabled: true,
              host: 'registry.example.com',
              port: 1234,
              api_url: 'http://localhost:1111',
              issuer: 'omnibus-gitlab-issuer',
              key: '/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key',
              notification_secret: nil,
              path: '/var/opt/gitlab/gitlab-rails/shared/registry'
            )
          end
        end

        context 'with external Registry' do
          before do
            stub_gitlab_rb(
              gitlab_rails: {
                registry_enabled: 'true',
                registry_key_path: '/fake/path',
                registry_host: 'registry.example.com',
                registry_api_url: 'http://registry.example.com:1234',
                registry_port: 1234,
                registry_issuer: 'foobar',
                registry_notification_secret: 'qwerty',
                registry_path: '/tmp/registry'
              }
            )
          end

          it 'renders gitlab.yml with correct registry settings' do
            expect(gitlab_yml[:production][:registry]).to eq(
              enabled: true,
              host: 'registry.example.com',
              port: 1234,
              api_url: 'http://registry.example.com:1234',
              issuer: 'foobar',
              key: '/fake/path',
              notification_secret: 'qwerty',
              path: '/tmp/registry'
            )
          end
        end
      end
    end
  end
end
