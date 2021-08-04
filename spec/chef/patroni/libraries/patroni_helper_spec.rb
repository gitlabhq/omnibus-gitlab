require 'chef_helper'

RSpec.describe PatroniHelper do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(step_into: %w(patroni)).converge('gitlab-ee::default')
  end

  subject(:helper) { PatroniHelper.new(chef_run.node) }
  let(:pg_helper) { PgHelper.new(chef_run.node) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe '#ctl_command' do
    it 'returns a full path to the ctl_command' do
      expect(helper.ctl_command).to eq('/opt/gitlab/embedded/bin/patronictl')
    end
  end

  describe '#bootstrapped?' do
    before do
      allow(File).to receive(:exist?).and_call_original
    end

    it 'returns true when patroni.dynamic.json exists in postgresql data directory' do
      allow(File).to receive(:exist?).with('/var/opt/gitlab/postgresql/data/patroni.dynamic.json').and_return(true)

      expect(helper.bootstrapped?).to eq(true)
    end

    it 'returns false when patroni.dynamic.json does not exist in postgresql data directory' do
      allow(File).to receive(:exist?).with('/var/opt/gitlab/postgresql/data/patroni.dynamic.json').and_return(false)

      expect(helper.bootstrapped?).to eq(false)
    end
  end

  describe '#dynamic_settings' do
    it 'returns a hash with required keys' do
      expected_root_keys = PatroniHelper::DCS_ATTRIBUTES + %w[postgresql slots]

      expect(helper.dynamic_settings(pg_helper).keys).to match_array(expected_root_keys)
    end

    context 'with standby cluster enabled' do
      it 'includes standby cluster attributes' do
        stub_gitlab_rb(
          patroni: {
            enable: true,
            standby_cluster: {
              enable: true
            }
          }
        )

        expected_root_keys = PatroniHelper::DCS_ATTRIBUTES + %w[postgresql slots standby_cluster]

        expect(helper.dynamic_settings(pg_helper).keys).to match_array(expected_root_keys)
      end
    end
  end

  describe '#node_status' do
    context 'when Patroni service is down' do
      before do
        allow_any_instance_of(OmnibusHelper).to receive(:service_up?).and_return(false)
        allow_any_instance_of(OmnibusHelper).to receive(:service_up?).with('patroni').and_return(false)
      end

      it 'returns not running' do
        expect(helper.node_status).to eq 'not running'
      end
    end

    context 'when Patroni service is up' do
      before do
        allow_any_instance_of(OmnibusHelper).to receive(:service_up?).and_return(false)
        allow_any_instance_of(OmnibusHelper).to receive(:service_up?).with('patroni').and_return(true)

        result = spy('shellout')
        allow(helper).to receive(:do_shell_out).and_return(result)
        allow(result).to receive(:stdout).and_return(' running')
      end

      it 'returns running current node state' do
        expect(helper.node_status).to eq 'running'
      end
    end
  end

  describe '#public_attributes' do
    context 'when patroni is enabled' do
      it 'returns a hash with required keys' do
        stub_gitlab_rb(
          patroni: {
            enable: true
          }
        )

        expected_patroni_keys = %w(config_dir data_dir log_dir api_address)

        expect(helper.public_attributes.keys).to match_array('patroni')
        expect(helper.public_attributes['patroni'].keys).to match_array(expected_patroni_keys)
      end
    end

    context 'when patroni is enabled with tls api' do
      it 'returns a hash with required keys' do
        stub_gitlab_rb(
          patroni: {
            enable: true,
            tls_certificate_file: '/path/to/crt.pem',
            tls_key_file: '/path/to/key.pem',
            tls_key_password: 'fakepassword',
            tls_ca_file: '/path/to/ca.pem',
            tls_ciphers: 'CIPHERS LIST',
            tls_client_mode: 'optional',
            tls_client_certificate_file: '/path/to/client.pem',
            tls_client_key_file: '/path/to/client.key'
          }
        )

        expected_tls_cfg = {
          'tls_verify' => true,
          'ca_file' => '/path/to/ca.pem',
          'verify_client' => true,
          'client_cert' => '/path/to/client.pem',
          'client_key' => '/path/to/client.key'
        }

        expect(helper.public_attributes.keys).to match_array('patroni')
        expect(helper.public_attributes['patroni']).to include(expected_tls_cfg)
        expect(helper.public_attributes['patroni']['api_address']).to start_with('https://')
      end
    end

    context 'when patroni is disabled' do
      it 'returns an empty hash' do
        expect(helper.public_attributes).to be_empty
      end
    end
  end
end
