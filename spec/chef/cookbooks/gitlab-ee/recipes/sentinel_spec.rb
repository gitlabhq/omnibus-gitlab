require 'chef_helper'

RSpec.describe 'gitlab::redis' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(redis_service sentinel_service runit_service)).converge('gitlab-ee::default') }
  let(:redis_master_ip) { '1.1.1.1' }
  let(:redis_announce_ip) { '10.10.10.10' }
  let(:redis_master_password) { 'blahblahblah' }
  let(:sentinel_conf) { '/var/opt/gitlab/sentinel/sentinel.conf' }
  let(:redis_sv_run) { '/opt/gitlab/sv/redis/run' }
  let(:sentinel_sv_run) { '/opt/gitlab/sv/sentinel/run' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe 'When sentinel is disabled' do
    before do
      stub_gitlab_rb(
        redis: {
          master_ip: redis_master_ip,
          announce_ip: redis_announce_ip,
          master_password: redis_master_password
        },
        redis_sentinel_role: {
          enable: false,
        }
      )
    end

    it_behaves_like 'disabled runit service', 'sentinel', 'root', 'root'
  end

  describe 'When sentinel is enabled' do
    context 'default values' do
      before do
        stub_gitlab_rb(
          redis: {
            enable: true,
            master_ip: redis_master_ip,
            announce_ip: redis_announce_ip,
            master_password: redis_master_password
          },
          redis_sentinel_role: {
            enable: true,
          }
        )
      end
      it 'creates redis user and group' do
        expect(chef_run).to create_account('user and group for sentinel').with(username: 'gitlab-redis', groupname: 'gitlab-redis')
      end

      it 'renders sentinel config file with default values' do
        expect(chef_run).to render_file('/var/opt/gitlab/sentinel/sentinel.conf')
          .with_content { |content|
            expect(content).to match(%r{bind 0.0.0.0})
            expect(content).to match(%r{port 26379})
            expect(content).to match(%r{sentinel announce-ip 10.10.10.10})
            expect(content).to match(%r{sentinel monitor gitlab-redis 1.1.1.1 6379 1})
            expect(content).to match(%r{sentinel down-after-milliseconds gitlab-redis 10000})
            expect(content).to match(%r{sentinel failover-timeout gitlab-redis 60000})
            expect(content).to match(%r{sentinel auth-pass gitlab-redis blahblahblah})
            expect(content).not_to match(%r{^tls})
            expect(content).to match(%r{SENTINEL resolve-hostnames no})
            expect(content).to match(%r{SENTINEL announce-hostnames no})
          }
      end

      it 'renders redis service definition without --replica-announce-ip' do
        expect(chef_run).to render_file(redis_sv_run).with_content { |content|
          expect(content).not_to match(%r{--replica-announce-ip "\$\(hostname -f\)"})
        }
        expect(chef_run).to render_file(sentinel_sv_run).with_content { |content|
          expect(content).not_to match(%r{'--sentinel announce-ip' "\$\(hostname -f\)"})
        }
      end

      it_behaves_like 'enabled runit service', 'sentinel', 'root', 'root'

      context 'user overrides sentinel_use_hostnames' do
        before do
          stub_gitlab_rb(
            sentinel: {
              use_hostnames: true
            }
          )
        end

        it 'uses hostnames' do
          expect(chef_run).to render_file(sentinel_conf).with_content { |content|
            expect(content).to match(%r{SENTINEL resolve-hostnames yes})
            expect(content).to match(%r{SENTINEL announce-hostnames yes})
          }
        end
      end

      context 'user enables announce_ip_from_hostname' do
        before do
          stub_gitlab_rb(
            redis: {
              enable: true,
              master_ip: redis_master_ip,
              announce_ip_from_hostname: true,
              master_password: redis_master_password
            })
        end

        it 'uses hostnames' do
          expect(chef_run).to render_file(sentinel_conf).with_content { |content|
            expect(content).to match(%r{SENTINEL resolve-hostnames yes})
            expect(content).to match(%r{SENTINEL announce-hostnames yes})
          }

          expect(chef_run).to render_file(redis_sv_run).with_content { |content|
            expect(content).to match(%r{--replica-announce-ip "\$\(hostname -f\)"})
          }
          expect(chef_run).to render_file(sentinel_sv_run).with_content { |content|
            expect(content).to match(%r{'--sentinel announce-ip' "\$\(hostname -f\)"})
          }
        end
      end
    end

    context 'user specified values' do
      before do
        stub_gitlab_rb(
          redis_sentinel_role: {
            enable: true,
          },
          redis: {
            username: 'foo',
            group: 'bar',
            master_ip: redis_master_ip,
            announce_ip: 'fake.hostname.local',
            master_password: redis_master_password
          }
        )
      end
      it 'creates redis user and group' do
        expect(chef_run).to create_account('user and group for sentinel').with(username: 'foo', groupname: 'bar')
      end

      it_behaves_like 'enabled runit service', 'sentinel', 'root', 'root'

      it 'uses hostnames' do
        expect(chef_run).to render_file(sentinel_conf).with_content { |content|
          expect(content).to match(%r{SENTINEL resolve-hostnames yes})
          expect(content).to match(%r{SENTINEL announce-hostnames yes})
        }
      end

      context 'user overrides sentinel_use_hostnames' do
        before do
          stub_gitlab_rb(
            sentinel: {
              use_hostnames: false
            }
          )
        end

        it 'does not use hostnames' do
          expect(chef_run).to render_file(sentinel_conf).with_content { |content|
            expect(content).to match(%r{SENTINEL resolve-hostnames no})
            expect(content).to match(%r{SENTINEL announce-hostnames no})
          }
        end
      end
    end

    context 'with tls settings specified' do
      before do
        stub_gitlab_rb(
          redis: {
            master_ip: redis_master_ip,
            announce_ip: redis_announce_ip,
            master_password: redis_master_password,
          },
          redis_sentinel_role: {
            enable: true
          },
          sentinel: {
            tls_port: 6380,
            tls_cert_file: '/etc/gitlab/ssl/redis.crt',
            tls_key_file: '/etc/gitlab/ssl/redis.key',
            tls_dh_params_file: '/etc/gitlab/ssl/redis-dhparams',
            tls_ca_cert_file: '/etc/gitlab/ssl/redis-ca.crt',
            tls_ca_cert_dir: '/opt/gitlab/embedded/ssl/certs',
            tls_auth_clients: 'no',
            tls_replication: 'yes',
            tls_cluster: 'yes',
            tls_protocols: 'TLSv1.2 TLSv1.3',
            tls_ciphers: 'DEFAULT:!MEDIUM',
            tls_ciphersuites: 'TLS_CHACHA20_POLY1305_SHA256',
            tls_prefer_server_ciphers: 'yes',
            tls_session_caching: 'no',
            tls_session_cache_size: 10000,
            tls_session_cache_timeout: 120
          }
        )
      end

      it 'renders sentinel config file with specified tls values' do
        expect(chef_run).to render_file('/var/opt/gitlab/sentinel/sentinel.conf')
          .with_content { |content|
            expect(content).to match(%r{^tls-port 6380$})
            expect(content).to match(%r{^tls-cert-file /etc/gitlab/ssl/redis.crt$})
            expect(content).to match(%r{^tls-key-file /etc/gitlab/ssl/redis.key$})
            expect(content).to match(%r{^tls-dh-params-file /etc/gitlab/ssl/redis-dhparams$})
            expect(content).to match(%r{^tls-ca-cert-file /etc/gitlab/ssl/redis-ca.crt$})
            expect(content).to match(%r{^tls-ca-cert-dir /opt/gitlab/embedded/ssl/certs$})
            expect(content).to match(%r{^tls-auth-clients no$})
            expect(content).to match(%r{^tls-replication yes$})
            expect(content).to match(%r{^tls-cluster yes$})
            expect(content).to match(%r{^tls-protocols "TLSv1.2 TLSv1.3"$})
            expect(content).to match(%r{^tls-ciphers DEFAULT:!MEDIUM$})
            expect(content).to match(%r{^tls-ciphersuites TLS_CHACHA20_POLY1305_SHA256$})
            expect(content).to match(%r{^tls-prefer-server-ciphers yes$})
            expect(content).to match(%r{^tls-session-caching no$})
            expect(content).to match(%r{^tls-session-cache-size 10000$})
            expect(content).to match(%r{^tls-session-cache-timeout 120$})
          }
      end
    end
  end

  context 'log directory and runit group' do
    context 'default values' do
      before do
        stub_gitlab_rb(
          redis: {
            enable: true,
            master_ip: redis_master_ip,
            announce_ip: redis_announce_ip,
            master_password: redis_master_password
          },
          redis_sentinel_role: {
            enable: true,
          }
        )
      end
      it_behaves_like 'enabled logged service', 'sentinel', true, { log_directory_owner: 'gitlab-redis' }
    end

    context 'custom values' do
      before do
        stub_gitlab_rb(
          redis: {
            enable: true,
            master_ip: redis_master_ip,
            announce_ip: redis_announce_ip,
            master_password: redis_master_password
          },
          redis_sentinel_role: {
            enable: true,
          },
          sentinel: {
            log_group: 'fugee'
          }
        )
      end
      it_behaves_like 'enabled logged service', 'sentinel', true, { log_directory_owner: 'gitlab-redis', log_group: 'fugee' }
    end
  end
end
