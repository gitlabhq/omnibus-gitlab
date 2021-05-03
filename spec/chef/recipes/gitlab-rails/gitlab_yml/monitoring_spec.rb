require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'Monitoring settings' do
    context 'with default configuration' do
      it 'renders gitlab.yml with default values' do
        expect(gitlab_yml[:production][:monitoring]).to eq(
          unicorn_sampler_interval: 10,
          ip_whitelist: %w[127.0.0.0/8 ::1/128],
          sidekiq_exporter: {
            enabled: true,
            log_enabled: false,
            port: 8082,
            address: '127.0.0.1'
          },
          web_exporter: {
            enabled: false,
            port: 8083,
            address: '127.0.0.1'
          }
        )
      end
    end

    context 'with user specified configuration' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            monitoring_whitelist: %w[1.0.0.0 2.0.0.0],
            monitoring_unicorn_sampler_interval: 50
          }
        )
      end

      it 'renders gitlab.rb with user specified values' do
        expect(gitlab_yml[:production][:monitoring][:ip_whitelist]).to eq(%w[1.0.0.0 2.0.0.0])
        expect(gitlab_yml[:production][:monitoring][:unicorn_sampler_interval]).to eq(50)
      end

      context 'when sidekiq exports logs' do
        before do
          stub_gitlab_rb(
            sidekiq: {
              metrics_enabled: false,
              exporter_log_enabled: true,
              listen_address: '1.2.3.4',
              listen_port: 1234
            }
          )
        end

        it 'renders gitlab.rb with user specified values' do
          expect(gitlab_yml[:production][:monitoring][:sidekiq_exporter]).to eq(
            enabled: false,
            log_enabled: true,
            port: 1234,
            address: '1.2.3.4'
          )
        end
      end

      context 'when webserver exports are enabled' do
        context 'with Puma' do
          before do
            stub_gitlab_rb(
              puma: {
                enable: true,
                exporter_enabled: false,
                exporter_address: '1.2.3.4',
                exporter_port: 1234
              }
            )
          end

          it 'renders gitlab.rb with user specified values' do
            expect(gitlab_yml[:production][:monitoring][:web_exporter]).to eq(
              enabled: false,
              port: 1234,
              address: '1.2.3.4'
            )
          end
        end

        context 'with Unicorn' do
          before do
            stub_gitlab_rb(
              puma: {
                enable: false
              },
              unicorn: {
                exporter_enabled: false,
                exporter_address: '1.2.3.4',
                exporter_port: 1234
              }
            )
          end

          it 'renders gitlab.rb with user specified values' do
            expect(gitlab_yml[:production][:monitoring][:web_exporter]).to eq(
              enabled: false,
              port: 1234,
              address: '1.2.3.4'
            )
          end
        end
      end
    end
  end
end
