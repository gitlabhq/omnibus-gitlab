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
end
