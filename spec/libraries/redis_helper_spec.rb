require 'chef_helper'

describe RedisHelper do
  let(:chef_run) { converge_config }
  subject { described_class.new(chef_run.node) }

  context '#redis_params' do
    context 'without sentinels' do
      before { allow(Gitlab).to receive(:[]).and_call_original }

      it 'returns correct parameters' do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_host: 'redis.example.com',
            redis_port: 8888,
            redis_password: 'mypass'
          }
        )
        expect(subject.redis_params).to eq(['redis.example.com', 8888, 'mypass'])
        expect(subject.redis_params(support_sentinel_groupname: false)).to eq(['redis.example.com', 8888, 'mypass'])
      end
    end

    context 'with sentinels' do
      before { allow(Gitlab).to receive(:[]).and_call_original }

      it 'returns correct parameters' do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_host: 'redis.example.com',
            redis_port: 8888,
            redis_password: 'mypass',
            redis_sentinels: [
              { 'host' => 'sentinel1.example.com', 'port' => '12345' },
              { 'host' => 'sentinel2.example.com', 'port' => '12345' }
            ]
          },
          redis: {
            master_name: 'master_from.redis.master_name',
            master_password: 'password_from.redis.master_password'
          }
        )
        expect(subject.redis_params).to eq(['master_from.redis.master_name', 6379, 'password_from.redis.master_password'])
        expect(subject.redis_params(support_sentinel_groupname: false)).to eq(['redis.example.com', 8888, 'mypass'])
      end
    end
  end

  context '#redis_url' do
    context 'with default configuration' do
      it 'returns a unix socket' do
        expect(subject.redis_url.to_s).to eq('unix:/var/opt/gitlab/redis/redis.socket')
      end
    end

    context 'with custom configuration' do
      before { allow(Gitlab).to receive(:[]).and_call_original }

      it 'returns a Redis URL when redis_host is defined' do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_host: 'redis.example.com'
          }
        )

        expect(subject.redis_url.to_s).to eq('redis://redis.example.com/')
      end

      it 'returns a Redis URL with port when a non default port is defined' do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_host: 'redis.example.com',
            redis_port: 8888
          }
        )

        expect(subject.redis_url.to_s).to eq('redis://redis.example.com:8888/')
      end

      it 'returns a Redis URL with database when specified' do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_host: 'redis.example.com',
            redis_database: 0
          }
        )

        expect(subject.redis_url.to_s).to eq('redis://redis.example.com/0')
      end

      it 'returns a Redis URL with password when specified' do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_host: 'redis.example.com',
            redis_password: 'mypass'
          }
        )

        expect(subject.redis_url.to_s).to eq('redis://:mypass@redis.example.com/')
      end

      it 'returns a Redis URL with an encoded password' do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_host: 'redis.example.com',
            redis_password: '#223'
          }
        )

        expect(subject.redis_url.to_s).to eq('redis://:%23223@redis.example.com/')
      end

      it 'returns a Redis URL with password, port and database when all specified' do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_host: 'redis.example.com',
            redis_password: 'mypass',
            redis_database: 0,
            redis_port: 8888
          }
        )

        expect(subject.redis_url.to_s).to eq('redis://:mypass@redis.example.com:8888/0')
      end

      it 'returns an SSL Redis URL with password, port and database when all specified' do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_host: 'redis.example.com',
            redis_password: 'mypass',
            redis_database: 0,
            redis_port: 8888,
            redis_ssl: true
          }
        )

        expect(subject.redis_url.to_s).to eq('rediss://:mypass@redis.example.com:8888/0')
      end
    end
  end

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
