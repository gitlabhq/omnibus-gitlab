require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'Monitoring settings' do
    context 'with default configuration' do
      it 'renders gitlab.yml with default values' do
        expect(gitlab_yml[:production][:monitoring]).to eq(
          ip_whitelist: %w[127.0.0.0/8 ::1/128],
          sidekiq_exporter: {
            enabled: true,
            log_enabled: false,
            port: 8082,
            address: '127.0.0.1'
          },
          sidekiq_health_checks: {
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
          }
        )
      end

      it 'renders gitlab.rb with user specified values' do
        expect(gitlab_yml[:production][:monitoring][:ip_whitelist]).to eq(%w[1.0.0.0 2.0.0.0])
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

      context 'when sidekiq exporter uses custom settings' do
        let(:exporter_settings) do
          {
            sidekiq: {
              metrics_enabled: false,
              exporter_log_enabled: true,
              listen_address: '1.2.2.2',
              listen_port: 2222
            }
          }
        end

        before do
          stub_gitlab_rb(exporter_settings.merge(health_checks_settings))
        end

        context 'when health-checks are not configured manually' do
          let(:health_checks_settings) { {} }

          it 'defaults health-checks to exporter settings' do
            expect(gitlab_yml[:production][:monitoring][:sidekiq_health_checks]).to eq(
              enabled: false,
              log_enabled: true,
              port: 2222,
              address: '1.2.2.2'
            )
          end
        end

        context 'when health-checks are configured manually' do
          let(:health_checks_settings) do
            {
              sidekiq: {
                health_checks_enabled: true,
                health_checks_log_enabled: true,
                health_checks_listen_address: '1.2.3.5',
                health_checks_listen_port: 1235
              }
            }
          end

          it 'uses custom health-checks settings' do
            expect(gitlab_yml[:production][:monitoring][:sidekiq_health_checks]).to eq(
              enabled: true,
              log_enabled: true,
              port: 1235,
              address: '1.2.3.5'
            )
          end
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
      end
    end
  end
end
