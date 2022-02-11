require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'Consul settings' do
    context 'with default values' do
      it 'renders gitlab.yml without Consul settings' do
        expect(gitlab_yml[:production][:consul]).to eq(
          api_url: ""
        )
      end
    end

    context 'with user specified values' do
      context 'when bundled consul is enabled' do
        before do
          stub_gitlab_rb(
            consul: {
              enable: true
            }
          )
        end

        it 'renders gitlab.yml with default Consul settings' do
          expect(gitlab_yml[:production][:consul]).to eq(
            api_url: 'http://localhost:8500'
          )
        end
      end

      context 'when Consul is running on non-default location' do
        context 'when setting client_addr and ports' do
          before do
            stub_gitlab_rb(
              consul: {
                enable: true,
                configuration: {
                  client_addr: '10.0.0.1',
                  ports: {
                    http: 1234
                  }
                }
              }
            )
          end

          it 'renders gitlab.yml with specified Consul settings' do
            expect(gitlab_yml[:production][:consul]).to eq(
              api_url: 'http://10.0.0.1:1234'
            )
          end
        end

        context 'when setting addresses and ports' do
          before do
            stub_gitlab_rb(
              consul: {
                enable: true,
                configuration: {
                  addresses: {
                    http: '10.0.1.2',
                  },
                  ports: {
                    http: 1234
                  }
                }
              }
            )
          end

          it 'renders gitlab.yml with specified Consul settings' do
            expect(gitlab_yml[:production][:consul]).to eq(
              api_url: 'http://10.0.1.2:1234'
            )
          end
        end

        context 'when http port is disabled via negative port number' do
          before do
            stub_gitlab_rb(
              consul: {
                enable: true,
                configuration: {
                  addresses: {
                    https: '10.0.1.2',
                  },
                  ports: {
                    http: -1,
                    https: 1234
                  }
                }
              }
            )
          end

          it 'renders gitlab.yml with specified Consul settings' do
            expect(gitlab_yml[:production][:consul]).to eq(
              api_url: 'https://10.0.1.2:1234'
            )
          end
        end
      end

      context 'when tls is enabled' do
        before do
          stub_gitlab_rb(
            consul: {
              enable: true,
              use_tls: true
            }
          )
        end

        it 'renders gitlab.yml with specified Consul settings' do
          expect(gitlab_yml[:production][:consul]).to eq(
            api_url: 'https://localhost:8501'
          )
        end
      end
    end
  end
end
