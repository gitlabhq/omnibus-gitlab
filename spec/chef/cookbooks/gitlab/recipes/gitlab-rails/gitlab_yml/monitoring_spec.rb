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
            address: '127.0.0.1',
            tls_enabled: false,
            tls_cert_path: nil,
            tls_key_path: nil
          },
          sidekiq_health_checks: {
            enabled: true,
            port: 8092,
            address: '127.0.0.1'
          },
          web_exporter: {
            enabled: false,
            port: 8083,
            address: '127.0.0.1',
            tls_enabled: false,
            tls_cert_path: nil,
            tls_key_path: nil
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

      context 'when Sidekiq health-checks are configured manually' do
        let(:health_checks_settings) do
          {
            health_checks_enabled: true,
            health_checks_listen_address: '1.2.3.5',
            health_checks_listen_port: 1235
          }
        end

        it 'uses custom health-checks settings' do
          stub_gitlab_rb(sidekiq: health_checks_settings)

          expect(gitlab_yml[:production][:monitoring][:sidekiq_health_checks]).to eq(
            enabled: true,
            port: 1235,
            address: '1.2.3.5'
          )
        end
      end

      context 'when Sidekiq dedicated metrics server uses custom settings' do
        let(:custom_config) do
          {
            metrics_enabled: false,
            exporter_log_enabled: true,
            listen_address: '1.2.2.2',
            listen_port: 2222
          }
        end

        it 'renders gitlab.rb with user specified values' do
          stub_gitlab_rb(sidekiq: custom_config)

          expect(gitlab_yml[:production][:monitoring][:sidekiq_exporter]).to include(
            enabled: false,
            log_enabled: true,
            address: '1.2.2.2',
            port: 2222
          )
        end

        context 'when TLS support is enabled' do
          let(:tls_config) do
            {
              exporter_tls_enabled: true,
              exporter_tls_cert_path: '/path/to/cert.pem',
              exporter_tls_key_path: '/path/to/key.pem'
            }
          end

          it 'renders gitlab.rb with user specified values' do
            stub_gitlab_rb(sidekiq: tls_config)

            expect(gitlab_yml[:production][:monitoring][:sidekiq_exporter]).to include(
              tls_enabled: true,
              tls_cert_path: '/path/to/cert.pem',
              tls_key_path: '/path/to/key.pem'
            )
          end
        end
      end

      context 'when Puma dedicated metrics server uses custom settings' do
        let(:custom_config) do
          {
            enable: true,
            exporter_enabled: false,
            exporter_address: '1.2.3.4',
            exporter_port: 1234
          }
        end

        it 'renders gitlab.rb with user specified values' do
          stub_gitlab_rb(puma: custom_config)

          expect(gitlab_yml[:production][:monitoring][:web_exporter]).to include(
            enabled: false,
            port: 1234,
            address: '1.2.3.4'
          )
        end

        context 'when TLS support is enabled' do
          let(:tls_config) do
            {
              exporter_tls_enabled: true,
              exporter_tls_cert_path: '/path/to/cert.pem',
              exporter_tls_key_path: '/path/to/key.pem'
            }
          end

          it 'renders gitlab.rb with user specified values' do
            stub_gitlab_rb(puma: tls_config)

            expect(gitlab_yml[:production][:monitoring][:web_exporter]).to include(
              tls_enabled: true,
              tls_cert_path: '/path/to/cert.pem',
              tls_key_path: '/path/to/key.pem'
            )
          end
        end
      end
    end
  end
end
