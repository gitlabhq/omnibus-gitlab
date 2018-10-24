require 'chef_helper'

describe 'gitlab::config' do
  cached(:chef_run) { converge_config }
  let(:node) { chef_run.node }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  shared_examples 'regular services are disabled' do
    it 'disables regular services' do
      expect(node['gitlab']['unicorn']['enable']).to eq false
      expect(node['gitlab']['sidekiq']['enable']).to eq false
      expect(node['gitlab']['gitlab-workhorse']['enable']).to eq false
      expect(node['gitaly']['enable']).to eq false
      expect(node['gitlab']['nginx']['enable']).to eq false
      expect(node['gitlab']['postgresql']['enable']).to eq false
      expect(node['gitlab']['mailroom']['enable']).to eq false
      expect(node['gitlab']['gitlab-monitor']['enable']).to eq false
      expect(node['gitlab']['postgres-exporter']['enable']).to eq false
      expect(node['gitlab']['prometheus']['enable']).to eq false
    end
  end

  it 'ignores unsupported top level variables' do
    Gitlab.instance_eval('abc="top-level"')

    expect(node['gitlab']['abc']).to be_nil
  end

  it 'errors on unsupported nested variables' do
    expect do
      Gitlab.instance_eval('abc["def"]["hij"] = "top-level"')
    end.to raise_error(NoMethodError).and(
      output(/ERROR: Encountered unsupported config key/).to_stdout
    )
  end

  context 'when gitlab-rails is disabled' do
    cached(:chef_run) { converge_config }
    before do
      stub_gitlab_rb(
        gitlab_rails: {
          enable: false
        }
      )
    end

    it 'disables Gitlab components' do
      expect(node['gitlab']['unicorn']['enable']).to eq false
      expect(node['gitlab']['sidekiq']['enable']).to eq false
      expect(node['gitlab']['gitlab-workhorse']['enable']).to eq false
      expect(node['gitlab']['gitlab-monitor']['enable']).to eq false
    end

    it 'still leaves other default service enabled' do
      expect(node['gitlab']['nginx']['enable']).to eq true
      expect(node['gitlab']['postgresql']['enable']).to eq true
      expect(node['redis']['enable']).to eq true
      expect(node['gitlab']['prometheus']['enable']).to eq true
      expect(node['gitlab']['alertmanager']['enable']).to eq true
      expect(node['gitlab']['node-exporter']['enable']).to eq true
      expect(node['gitlab']['redis-exporter']['enable']).to eq true
      expect(node['gitlab']['logrotate']['enable']).to eq true
      expect(node['gitlab']['postgres-exporter']['enable']).to eq true
    end
  end

  context 'with roles' do
    context 'when redis_sentinel_role is enabled' do
      cached(:chef_run) { converge_config(ee: true) }
      before do
        stub_gitlab_rb(
          redis_sentinel_role: {
            enable: true
          },
          redis: {
            master_password: 'PASSWORD',
            master_ip: '10.0.0.0'
          }
        )
      end

      it_behaves_like 'regular services are disabled'

      it 'only sentinel is enabled' do
        expect(node['gitlab']['sentinel']['enable']).to eq true
        expect(node['redis']['enable']).to eq false
        expect(node['gitlab']['redis-exporter']['enable']).to eq false
        expect(node['gitlab']['node-exporter']['enable']).to eq true
        expect(node['gitlab']['logrotate']['enable']).to eq true
      end

      context 'when redis_sentinel_role is enabled with redis_master_role' do
        cached(:chef_run) { converge_config(ee: true) }
        before do
          stub_gitlab_rb(
            redis_sentinel_role: {
              enable: true
            },
            redis_master_role: {
              enable: true
            }
          )
        end

        it_behaves_like 'regular services are disabled'

        it 'redis and sentinel are enabled' do
          expect(node['gitlab']['sentinel']['enable']).to eq true
          expect(node['redis']['enable']).to eq true
          expect(node['gitlab']['redis-exporter']['enable']).to eq true
          expect(node['gitlab']['node-exporter']['enable']).to eq true
          expect(node['gitlab']['logrotate']['enable']).to eq true
        end
      end

      context 'when redis_sentinel_role is enabled with redis_slave_role' do
        cached(:chef_run) { converge_config(ee: true) }
        before do
          stub_gitlab_rb(
            redis_sentinel_role: {
              enable: true
            },
            redis_slave_role: {
              enable: true
            },
            redis: {
              master_ip: '10.0.0.0',
              master_port: 6379,
              master_password: 'PASSWORD'
            }
          )
        end

        it_behaves_like 'regular services are disabled'

        it 'only redis is enabled' do
          expect(node['gitlab']['sentinel']['enable']).to eq true
          expect(node['redis']['enable']).to eq true
          expect(node['gitlab']['redis-exporter']['enable']).to eq true
          expect(node['gitlab']['node-exporter']['enable']).to eq true
          expect(node['gitlab']['logrotate']['enable']).to eq true
        end
      end
    end

    context 'when redis_master_role is enabled' do
      cached(:chef_run) { converge_config(ee: true) }
      before do
        stub_gitlab_rb(
          redis_master_role: {
            enable: true
          }
        )
      end

      it_behaves_like 'regular services are disabled'

      it 'only redis is enabled' do
        expect(node['redis']['enable']).to eq true
        expect(node['gitlab']['sentinel']['enable']).to eq false
        expect(node['gitlab']['redis-exporter']['enable']).to eq true
        expect(node['gitlab']['node-exporter']['enable']).to eq true
        expect(node['gitlab']['logrotate']['enable']).to eq true
      end
    end

    context 'when redis_slave_role is enabled' do
      cached(:chef_run) { converge_config(ee: true) }
      before do
        stub_gitlab_rb(
          redis_slave_role: {
            enable: true
          },
          redis: {
            master_ip: '10.0.0.0',
            master_port: 6379,
            master_password: 'PASSWORD'
          }
        )
      end

      it_behaves_like 'regular services are disabled'

      it 'only redis is enabled' do
        expect(node['redis']['enable']).to eq true
        expect(node['gitlab']['sentinel']['enable']).to eq false
      end
    end

    context 'when redis_master_role and redis_slave_role are enabled' do
      cached(:chef_run) { converge_config(ee: true) }
      before do
        stub_gitlab_rb(
          redis_master_role: {
            enable: true
          },
          redis_slave_role: {
            enable: true
          },
          redis: {
            master_ip: '10.0.0.0',
            master_port: 6379,
            master_password: 'PASSWORD'
          }
        )
      end

      it 'fails with an error' do
        expect { chef_run }.to raise_error RuntimeError
      end
    end
  end
end
