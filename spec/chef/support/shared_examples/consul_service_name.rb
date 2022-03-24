RSpec.shared_examples 'consul service discovery' do |gitlab_rb_key, service_name|
  let(:gitlab_rb_setting) do
    {
      consul: {
        enable: true,
        monitoring_service_discovery: true
      }
    }
  end

  describe 'consul service discovery' do
    let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

    context 'by default' do
      it 'is not registered as consul service' do
        expect(chef_run).not_to create_consul_service(service_name)
      end
    end

    context 'when enabled' do
      before do
        stub_gitlab_rb(gitlab_rb_setting)
      end

      it 'is registered as a consul service with default name' do
        expect(chef_run).to create_consul_service(service_name)
      end

      context 'with user specified service name' do
        before do
          gitlab_rb_setting[gitlab_rb_key] = {
            enable: true,
            consul_service_name: "#{service_name}-foobar"
          }
          stub_gitlab_rb(gitlab_rb_setting)
        end

        it 'is registered as a consul service with user specified name' do
          expect(chef_run).to create_consul_service("#{service_name}-foobar")
        end
      end
    end
  end
end
