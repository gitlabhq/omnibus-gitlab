require 'chef_helper'

RSpec.describe SentinelHelper do
  let(:chef_run) { converge_config(is_ee: true) }
  subject { described_class.new(chef_run.node) }
  before { allow(Gitlab).to receive(:[]).and_call_original }

  context '#running_version' do
    let(:cmd) { '/opt/gitlab/embedded/bin/redis-cli -h 0.0.0.0 -p 26379 INFO' }
    let(:status_success) { double("status", stdout: 'redis_version:1.2.3', exitstatus: 0) }
    let(:gitlab_rb) do
      {
        redis: {
          master_ip: '127.0.0.1',
          master_password: 'masterpass'
        },
        sentinel: {
          enable: true,
          password: sentinel_password
        }
      }
    end

    before do
      allow_any_instance_of(OmnibusHelper).to receive(:service_up?).with('sentinel').and_return(true)
      stub_gitlab_rb(gitlab_rb)
    end

    context 'with a Sentinel password defined' do
      let(:sentinel_password) { 'some password' }

      it 'sets REDISCLI_AUTH' do
        expect(VersionHelper).to receive(:do_shell_out).with(cmd, env: { 'REDISCLI_AUTH' => sentinel_password }).and_return(status_success)

        expect(subject.running_version).to eq('1.2.3')
      end
    end

    context 'without a Sentinel password defined' do
      let(:sentinel_password) { nil }

      it 'does not set REDISCLI_AUTH' do
        expect(VersionHelper).to receive(:do_shell_out).with(cmd, env: {}).and_return(status_success)

        expect(subject.running_version).to eq('1.2.3')
      end
    end

    context 'with both TLS and unencrypted ports disabled' do
      let(:gitlab_rb) do
        {
          sentinel: {
            port: 0,
            tls_port: 0
          }
        }
      end

      it 'raises an error' do
        expect { subject.running_version }.to raise_error("No Sentinel port available: sentinel['port'] or sentinel['tls_port'] must be non-zero")
      end
    end

    context 'with TLS enabled' do
      let(:cmd) { "/opt/gitlab/embedded/bin/redis-cli -h 0.0.0.0 --tls -p 6380 --cacert '#{tls_ca_cert_file}' --cacertdir '#{tls_ca_cert_dir}' INFO" }
      let(:tls_auth_clients) { 'no' }
      let(:tls_cert_file) { '/etc/gitlab/ssl/redis.crt' }
      let(:tls_key_file) { '/etc/gitlab/ssl/redis.key' }
      let(:tls_ca_cert_file) { '/etc/gitlab/ssl/redis-ca.crt' }
      let(:tls_ca_cert_dir) { '/opt/gitlab/embedded/ssl/certs' }
      let(:gitlab_rb) do
        {
          sentinel: {
            port: 0,
            tls_port: 6380,
            tls_cert_file: tls_cert_file,
            tls_key_file: tls_key_file,
            tls_dh_params_file: '/etc/gitlab/ssl/redis-dhparams',
            tls_ca_cert_file: tls_ca_cert_file,
            tls_ca_cert_dir: tls_ca_cert_dir,
            tls_auth_clients: tls_auth_clients
          }
        }
      end

      it 'connects with TLS server certificates' do
        expect(VersionHelper).to receive(:do_shell_out).with(cmd, env: {}).and_return(status_success)

        expect(subject.running_version).to eq('1.2.3')
      end

      context 'with TLS client certs required' do
        let(:tls_auth_clients) { 'yes' }
        let(:cmd) { "/opt/gitlab/embedded/bin/redis-cli -h 0.0.0.0 --tls -p 6380 --cacert '#{tls_ca_cert_file}' --cacertdir '#{tls_ca_cert_dir}' --cert '#{tls_cert_file}' --key '#{tls_key_file}' INFO" }

        it 'connects with TLS server and client certificates' do
          expect(VersionHelper).to receive(:do_shell_out).with(cmd, env: {}).and_return(status_success)

          expect(subject.running_version).to eq('1.2.3')
        end

        context 'with missing TLS client cert' do
          let(:tls_key_file) { nil }

          it 'raises an error' do
            expect { subject.running_version }.to raise_error("Sentinel TLS client authentication requires sentinel['tls_cert_file'] and sentinel['tls_key_file'] options")
          end
        end
      end
    end
  end

  context '#myid' do
    context 'when retrieving from config' do
      it 'fails when myid is not 40 hex-characters long' do
        stub_gitlab_rb(
          sentinel: {
            myid: 'wrongid'
          }
        )

        expect { subject.myid }.to raise_error RuntimeError
      end

      it 'works when myid is 40 hex-characters long' do
        stub_gitlab_rb(
          sentinel: {
            myid: '1234567890abcdef1234567890abcdef12345678'
          }
        )

        expect { subject.myid }.not_to raise_error
      end
    end

    context 'when no config is defined' do
      let(:myid) { 'abcdef1234567890abcdef1234567890abcdef1' }

      it 'generates a random myid' do
        expect(subject.myid).not_to be_empty
      end

      it 'persist generated value into JSON file' do
        allow(subject).to receive(:generate_myid).at_least(:once) { myid }

        expect(subject).to receive(:save_to_file).with({ 'myid' => myid })
        subject.myid
      end
    end
  end
end
