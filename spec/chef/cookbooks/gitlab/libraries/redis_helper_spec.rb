require 'chef_helper'

RSpec.describe RedisHelper do
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
        expect(subject.redis_url.to_s).to eq('unix:///var/opt/gitlab/redis/redis.socket')
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

  describe '#workhorse_params' do
    let(:baseline_config_with_sentinel) do
      {
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
      }
    end

    before { allow(Gitlab).to receive(:[]).and_call_original }

    context 'without external workhorse redis' do
      context 'when no sentinels are configured' do
        it 'renders parameters for workhorse redis' do
          stub_gitlab_rb(
            gitlab_rails: {
              redis_host: 'redis.example.com',
              redis_port: 8888,
              redis_password: 'mypass'
            }
          )

          params = subject.workhorse_params
          expect(params[:password]).to eq('mypass')
          expect(params[:sentinels]).to eq([])
          expect(params[:url].to_s).to eq('redis://:mypass@redis.example.com:8888/')
        end
      end

      context 'when sentinels are configured' do
        it 'renders parameters for workhorse redis' do
          stub_gitlab_rb(baseline_config_with_sentinel)

          params = subject.workhorse_params
          expect(params[:password]).to eq('password_from.redis.master_password')
          expect(params[:sentinels].map(&:to_s)).to eq(%w[redis://sentinel1.example.com:12345 redis://sentinel2.example.com:12345])
          expect(params[:sentinelMaster]).to eq('master_from.redis.master_name')
          expect(params[:sentinelPassword]).to be_nil
          expect(params[:url].to_s).to eq("redis://:password_from.redis.master_password@master_from.redis.master_name/")
        end
      end
    end

    context 'with external workhorse redis' do
      context 'when no sentinels are configured' do
        it 'renders parameters for workhorse redis' do
          stub_gitlab_rb(baseline_config_with_sentinel.merge({
                                                               gitlab_rails: {
                                                                 redis_workhorse_instance: "redis://:@redis.workhorse.com:8888",
                                                                 redis_workhorse_password: "workhorse.password"
                                                               }
                                                             }))

          params = subject.workhorse_params
          expect(params[:password]).to eq('workhorse.password')
          expect(params[:sentinels]).to eq([])
          expect(params[:url].to_s).to eq('redis://:@redis.workhorse.com:8888')
        end
      end

      context 'when sentinels are configured' do
        it 'renders parameters for workhorse redis' do
          stub_gitlab_rb(baseline_config_with_sentinel.merge({
                                                               gitlab_rails: {
                                                                 redis_workhorse_sentinels: [
                                                                   { 'host' => 'sentinel1.workhorse.com', 'port' => '12345' },
                                                                   { 'host' => 'sentinel2.workhorse.com', 'port' => '12345' }
                                                                 ],
                                                                 redis_workhorse_sentinels_password: "workhorse.password",
                                                                 redis_workhorse_sentinel_master: "workhorse.master"
                                                               }
                                                             }))

          params = subject.workhorse_params
          expect(params[:password]).to be_nil
          expect(params[:sentinels].map(&:to_s)).to eq(%w[redis://:workhorse.password@sentinel1.workhorse.com:12345 redis://:workhorse.password@sentinel2.workhorse.com:12345])
          expect(params[:sentinelMaster]).to eq('workhorse.master')
          expect(params[:sentinelPassword]).to eq('workhorse.password')
          expect(params[:url]).to eq(nil)
        end
      end
    end
  end
end
