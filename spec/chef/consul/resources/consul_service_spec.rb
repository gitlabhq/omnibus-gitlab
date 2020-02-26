require 'chef_helper'

describe 'consul_service' do
  let(:runner) do
    ChefSpec::SoloRunner.new(step_into: %w(consul_service))
  end

  context 'create' do
    before do
      runner.node.automatic['ipaddress'] = '10.1.1.1'
    end

    context 'with service address and port properties' do
      let(:chef_run) { runner.converge('test_consul::consul_service_address_port') }

      it 'creates the Consul service file' do
        expect(chef_run).to render_file('/var/opt/gitlab/consul/config.d/node-exporter-service.json')
          .with_content('{"service":{"name":"node-exporter","address":"10.1.1.1","port":1234}}')
      end

      it 'notifies the Consul service to reload' do
        expect(chef_run.file('/var/opt/gitlab/consul/config.d/node-exporter-service.json'))
          .to notify 'execute[reload consul]'
      end
    end

    context 'with a socket property and no reload' do
      let(:chef_run) { runner.converge('test_consul::consul_service_socket') }

      it 'creates the Consul service file' do
        expect(chef_run).to render_file('/var/opt/gitlab/consul/config.d/node-exporter-service.json')
          .with_content('{"service":{"name":"node-exporter","address":"10.1.1.1","port":5678}}')
      end

      it 'does not notify the Consul service to reload' do
        expect(chef_run.file('/var/opt/gitlab/consul/config.d/node-exporter-service.json'))
          .not_to notify 'execute[reload consul]'
      end
    end

    context 'with addvertise_addr property' do
      let(:chef_run) { runner.converge('test_consul::consul_service_advertise_addr') }
      
      it 'creates the Consul service file' do
        expect(chef_run).to render_file('/var/opt/gitlab/consul/config.d/node-exporter-service.json')
          .with_content('{"service":{"name":"node-exporter","port":1234,"advertise_addr":"1.1.1.1"}}')
      end
    end
  end

  context 'delete' do
    context 'default do reload' do
      let(:chef_run) { runner.converge('test_consul::consul_service_delete') }

      it 'deletes the Consul service file' do
        expect(chef_run).to delete_file('/var/opt/gitlab/consul/config.d/delete-me-service.json')
      end

      it 'notifies the Consul service to reload' do
        expect(chef_run.file('/var/opt/gitlab/consul/config.d/delete-me-service.json'))
          .to notify 'execute[reload consul]'
      end
    end

    context 'do not reload' do
      let(:chef_run) { runner.converge('test_consul::consul_service_delete_no_reload') }

      it 'does not notify the Consul service to reload' do
        expect(chef_run.file('/var/opt/gitlab/consul/config.d/delete-no-reload-service.json'))
          .not_to notify 'execute[reload consul]'
      end
    end
  end
end
