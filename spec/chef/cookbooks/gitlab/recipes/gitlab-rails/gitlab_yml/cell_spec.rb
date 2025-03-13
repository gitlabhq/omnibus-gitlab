require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'GitLab Application Settings' do
    describe 'Cell configuration' do
      context 'with default configuration' do
        it 'does not render cell in gitlab.yml' do
          expect(gitlab_yml[:production][:gitlab][:cell]).to be nil
        end
      end

      context 'when cell is enabled' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              cell: {
                enabled: true,
                id: 1,
                topology_service_client: {
                  address: 'topology-service.test.com:443',
                  ca_file: '/etc/ssl/certs/ca-certificate.crt',
                  certificate_file: '/etc/ssl/certs/certificate.crt',
                  private_key_file: '/etc/ssl/private/key.key',
                }
              }
            }
          )
        end

        it 'renders the relevant cell configuration in gitlab.yml' do
          expect(gitlab_yml[:production][:cell][:enabled]).to eq(true)
          expect(gitlab_yml[:production][:cell][:id]).to eq(1)
          expect(gitlab_yml[:production][:cell][:topology_service_client][:address]).to eq('topology-service.test.com:443')
          expect(gitlab_yml[:production][:cell][:topology_service_client][:ca_file]).to eq('/etc/ssl/certs/ca-certificate.crt')
          expect(gitlab_yml[:production][:cell][:topology_service_client][:certificate_file]).to eq('/etc/ssl/certs/certificate.crt')
          expect(gitlab_yml[:production][:cell][:topology_service_client][:private_key_file]).to eq('/etc/ssl/private/key.key')
        end
      end
    end
  end
end
