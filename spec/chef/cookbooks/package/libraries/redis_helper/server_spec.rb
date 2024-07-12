require 'chef_helper'

RSpec.describe RedisHelper::Server do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default') }

  subject { described_class.new(chef_run.node) }

  describe '#running_version' do
    let(:redis_cli_output) do
      <<~MSG
        # Server
        redis_version:3.2.12
        redis_git_sha1:00000000
        redis_git_dirty:0
        redis_build_id:e16da30f4a0a7845
        redis_mode:standalone
        os:Linux 4.15.0-58-generic x86_64
      MSG
    end

    before do
      # Un-doing the stub added in chef_helper
      allow_any_instance_of(described_class).to receive(:running_version).and_call_original
      allow(Gitlab).to receive(:[]).and_call_original
      allow(VersionHelper).to receive(:version).with(/redis-cli.*INFO/).and_return(redis_cli_output)
      allow_any_instance_of(OmnibusHelper).to receive(:service_up?).and_call_original
    end

    context 'when redis is not running' do
      it 'returns nil' do
        allow_any_instance_of(OmnibusHelper).to receive(:service_up?).with('redis').and_return(false)

        expect(subject.running_version).to be_nil
      end
    end

    context 'when redis is running' do
      before do
        allow_any_instance_of(OmnibusHelper).to receive(:service_up?).with('redis').and_return(true)
      end
      context 'over socket' do
        it 'calls VersionHelper.version with correct arguments' do
          expect(VersionHelper).to receive(:version).with('/opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket INFO')

          subject.running_version
        end
      end

      context 'over TCP' do
        context 'on non-TLS port' do
          before do
            stub_gitlab_rb(
              redis: {
                bind: '0.0.0.0',
                port: 6379
              }
            )
          end

          it 'calls VersionHelper.version with correct arguments' do
            expect(VersionHelper).to receive(:version).with('/opt/gitlab/embedded/bin/redis-cli -h 0.0.0.0 -p 6379 INFO')

            subject.running_version
          end
        end

        context 'on TLS port' do
          before do
            stub_gitlab_rb(
              redis: {
                bind: '0.0.0.0',
                tls_port: 6380,
                tls_cert_file: '/tmp/self_signed.crt',
                tls_key_file: '/tmp/self_signed.key',
                tls_auth_clients: 'yes'
              }
            )
          end

          it 'calls VersionHelper.version with correct arguments' do
            expected_args = "-h 0.0.0.0 --tls -p 6380 --cacert '/opt/gitlab/embedded/ssl/certs/cacert.pem' --cacertdir '/opt/gitlab/embedded/ssl/certs/' --cert '/tmp/self_signed.crt' --key '/tmp/self_signed.key'"
            expect(VersionHelper).to receive(:version).with("/opt/gitlab/embedded/bin/redis-cli #{expected_args} INFO")

            subject.running_version
          end
        end
      end

      context 'with a Redis password specified' do
        before do
          stub_gitlab_rb(
            redis: {
              bind: '0.0.0.0',
              port: 6379,
              password: 'toomanysecrets'
            }
          )
        end

        it 'it passes password to the command' do
          expect(VersionHelper).to receive(:version).with("/opt/gitlab/embedded/bin/redis-cli -h 0.0.0.0 -p 6379 -a 'toomanysecrets' INFO")

          subject.running_version
        end
      end

      it 'parses version from redis-cli output properly' do
        expect(subject.running_version).to eq('3.2.12')
      end
    end
  end

  describe '#installed_version' do
    let(:redis_server_output) { 'Redis server v=3.2.12 sha=00000000:0 malloc=jemalloc-4.0.3 bits=64 build=e16da30f4a0a7845' }

    before do
      # Un-doing the stub added in chef_helper
      allow_any_instance_of(described_class).to receive(:installed_version).and_call_original
      allow(Gitlab).to receive(:[]).and_call_original
      allow(VersionHelper).to receive(:version).with(/redis-server --version/).and_return(redis_server_output)
      allow_any_instance_of(OmnibusHelper).to receive(:service_up?).and_call_original
    end

    context 'when redis is not running' do
      it 'returns nil' do
        allow_any_instance_of(OmnibusHelper).to receive(:service_up?).with('redis').and_return(false)

        expect(subject.installed_version).to be_nil
      end
    end

    context 'when redis is running' do
      before do
        allow_any_instance_of(OmnibusHelper).to receive(:service_up?).with('redis').and_return(true)
      end

      it 'parses redis-server output properly' do
        expect(subject.installed_version).to eq('3.2.12')
      end
    end
  end
end
