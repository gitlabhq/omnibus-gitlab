require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'Prometheus settings' do
    context 'with default configuration' do
      it 'renders gitlab.yml with bundled Prometheus default values' do
        expect(gitlab_yml[:production][:prometheus]).to eq(
          enabled: true,
          server_address: 'localhost:9090'
        )
      end
    end

    context 'with user specified configuation' do
      context 'when bundled Prometheus is running on non-default address' do
        before do
          stub_gitlab_rb(
            prometheus: {
              listen_address: '0.0.0.0:9191'
            }
          )
        end

        it 'renders gitlab.yml with correct values' do
          expect(gitlab_yml[:production][:prometheus]).to eq(
            enabled: true,
            server_address: '0.0.0.0:9191'
          )
        end
      end

      context 'when bundled Prometheus is running on non-default address with only port specified' do
        before do
          stub_gitlab_rb(
            prometheus: {
              listen_address: ':8080'
            }
          )
        end

        it 'renders gitlab.yml with server address rendered as a string' do
          expect(gitlab_yml[:production][:prometheus]).to eq(
            enabled: true,
            server_address: ':8080'
          )
        end
      end

      context 'when configured with an external and internal Prometheus addresses' do
        before do
          stub_gitlab_rb(
            prometheus: {
              listen_address: '0.0.0.0:9191'
            },
            gitlab_rails: {
              prometheus_address: '1.1.1.1:2222'
            }
          )
        end

        it 'renders gitlab.yml with the external address' do
          expect(gitlab_yml[:production][:prometheus]).to eq(
            enabled: true,
            server_address: '1.1.1.1:2222'
          )
        end
      end

      context 'when bundled Prometheus is disabled and no external Prometheus address is specified' do
        before do
          stub_gitlab_rb(
            prometheus: {
              enable: false
            }
          )
        end

        it 'renders gitlab.yml with Prometheus disabled' do
          expect(gitlab_yml[:production][:prometheus][:enabled]).to be false
        end
      end

      context 'when bundled Prometheus is disabled but an external Prometheus address is specified' do
        before do
          stub_gitlab_rb(
            prometheus: {
              enable: false,
            },
            gitlab_rails: {
              prometheus_address: '1.2.3.4:2222'
            }
          )
        end

        it 'renders gitlab.yml with external Prometheus addreess' do
          expect(gitlab_yml[:production][:prometheus]).to eq(
            enabled: true,
            server_address: '1.2.3.4:2222'
          )
        end
      end
    end
  end
end
