require 'chef_helper'

RSpec.describe NewRedisHelper::GitlabWorkhorse do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default') }
  let(:workhorse_redis_yml_template) { chef_run.template('/var/opt/gitlab/gitlab-rails/etc/redis.workhorse.yml') }
  let(:workhorse_redis_yml_file_content) { ChefSpec::Renderer.new(chef_run, workhorse_redis_yml_template).content }
  let(:workhorse_redis_yml) { YAML.safe_load(workhorse_redis_yml_file_content, aliases: true, symbolize_names: true) }

  subject { described_class.new(chef_run.node) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context '#redis_params' do
    context 'by default' do
      it 'returns information about the default Redis instance' do
        expect(subject.redis_params).to eq(
          url: 'unix:///var/opt/gitlab/redis/redis.socket',
          password: nil,
          sentinels: [],
          sentinelMaster: 'gitlab-redis',
          sentinelPassword: nil
        )
      end
    end

    context 'with user specified values' do
      context 'when password set for UNIX socket' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              redis_password: 'redis-password'
            }
          )
        end

        it 'returns a UNIX socket URL with password' do
          expect(subject.redis_params).to eq(
            url: 'unix://:redis-password@/var/opt/gitlab/redis/redis.socket',
            password: 'redis-password',
            sentinels: [],
            sentinelMaster: 'gitlab-redis',
            sentinelPassword: nil
          )
        end
      end

      context 'when settings specified via gitlab_rails' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              redis_host: 'my.redis.host',
              redis_password: 'redis-password'
            }
          )
        end

        it 'returns information about the provided Redis instance via gitlab_rails' do
          expect(subject.redis_params).to eq(
            url: 'redis://:redis-password@my.redis.host/',
            password: 'redis-password',
            sentinels: [],
            sentinelMaster: 'gitlab-redis',
            sentinelPassword: nil
          )
        end
      end

      context 'when settings specified via gitlab_rails for separate Redis instance' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              redis_host: 'my.redis.host',
              redis_password: 'redis-password',
              redis_workhorse_instance: 'different.workhorse.redis.instance',
              redis_workhorse_password: 'different-redis-password'
            }
          )
        end

        it 'returns information about the provided Redis instance via gitlab_rails workhorse instance' do
          expect(subject.redis_params).to eq(
            url: 'redis://:different-redis-password@different.workhorse.redis.instance/',
            password: 'different-redis-password',
            sentinels: [],
            sentinelMaster: 'gitlab-redis',
            sentinelPassword: nil
          )
        end
      end

      context 'when settings specified via gitlab_workhorse' do
        context 'when pointing to different Redis instances' do
          before do
            stub_gitlab_rb(
              gitlab_rails: {
                redis_host: 'my.redis.host',
                redis_password: 'redis-password',
                redis_workhorse_instance: 'different.workhorse.redis.instance',
                redis_workhorse_password: 'different-redis-password'
              },
              gitlab_workhorse: {
                redis_host: 'workhorse.redis.host',
                redis_password: 'redis-workhorse-password'
              }
            )
          end

          it 'returns information about the provided Redis instance via gitlab_workhorse' do
            expect(subject.redis_params).to eq(
              url: 'redis://:redis-workhorse-password@workhorse.redis.host/',
              password: 'redis-workhorse-password',
              sentinels: [],
              sentinelMaster: 'gitlab-redis',
              sentinelPassword: nil
            )
          end

          # TODO: When Workhorse recipe spec is cleaned up, this should ideally
          # end up there.
          it 'populates workhorse.redis.yml with values from gitlab_workhorse' do
            expect(workhorse_redis_yml).to eq(
              production: {
                url: 'redis://:redis-workhorse-password@workhorse.redis.host/',
                secret_file: '/var/opt/gitlab/gitlab-rails/shared/encrypted_settings/redis.workhorse.yml.enc'
              }
            )
          end
        end

        context 'when pointing to same Redis instance' do
          before do
            stub_gitlab_rb(
              gitlab_rails: {
                redis_host: 'my.redis.host',
                redis_password: 'redis-password',
              },
              gitlab_workhorse: {
                redis_host: 'my.redis.host',
                redis_password: 'redis-password'
              }
            )
          end

          it 'returns information about the provided Redis instance via gitlab_workhorse' do
            expect(subject.redis_params).to eq(
              url: 'redis://:redis-password@my.redis.host/',
              password: 'redis-password',
              sentinels: [],
              sentinelMaster: 'gitlab-redis',
              sentinelPassword: nil
            )
          end

          # TODO: When Workhorse recipe spec is cleaned up, this should ideally
          # end up there.
          it 'does not populate workhorse.redis.yml' do
            expect(chef_run).not_to render_file('/var/opt/gitlab/gitlab-rails/etc/redis.workhorse.yml')
          end
        end
      end

      context 'when sentinels are specified' do
        context 'when Redis master settings are specified via redis key' do
          before do
            stub_gitlab_rb(
              gitlab_workhorse: {
                redis_host: 'workhorse.redis.host',
                redis_sentinels: [
                  { host: '10.0.0.1', port: 26379 },
                  { host: '10.0.0.2', port: 26379 },
                  { host: '10.0.0.3', port: 26379 }
                ],
                redis_sentinels_password: 'workhorse-sentinel-password'
              },
              redis: {
                master_name: 'redis-for-workhorse',
                master_password: 'redis-password'
              }
            )
          end

          it 'returns information about the provided Redis instance via gitlab_workhorse' do
            expect(subject.redis_params).to eq(
              url: 'redis://:redis-password@redis-for-workhorse/',
              password: 'redis-password',
              sentinels: [
                "redis://:workhorse-sentinel-password@10.0.0.1:26379",
                "redis://:workhorse-sentinel-password@10.0.0.2:26379",
                "redis://:workhorse-sentinel-password@10.0.0.3:26379"
              ],
              sentinelMaster: 'redis-for-workhorse',
              sentinelPassword: 'workhorse-sentinel-password'
            )
          end

          # TODO: When Workhorse recipe spec is cleaned up, this should ideally
          # end up there.
          it 'populates workhorse.redis.yml with values from gitlab_workhorse' do
            expect(workhorse_redis_yml).to eq(
              production: {
                url: 'redis://:redis-password@workhorse.redis.host/',
                secret_file: '/var/opt/gitlab/gitlab-rails/shared/encrypted_settings/redis.workhorse.yml.enc',
                sentinels: [
                  { host: '10.0.0.1', port: 26379, password: 'workhorse-sentinel-password' },
                  { host: '10.0.0.2', port: 26379, password: 'workhorse-sentinel-password' },
                  { host: '10.0.0.3', port: 26379, password: 'workhorse-sentinel-password' },
                ]
              }
            )
          end
        end
      end
    end
  end
end
