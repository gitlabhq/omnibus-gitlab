require 'chef_helper'

describe 'gitlab::config' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::config') }
  let(:node) { chef_run.node }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  shared_examples 'regular services are disabled' do
    it 'disables regular services' do
      expect(node['gitlab']['gitlab-rails']['enable']).to eq false
      expect(node['gitlab']['unicorn']['enable']).to eq false
      expect(node['gitlab']['sidekiq']['enable']).to eq false
      expect(node['gitlab']['gitlab-workhorse']['enable']).to eq false
      expect(node['gitlab']['bootstrap']['enable']).to eq false
      expect(node['gitlab']['nginx']['enable']).to eq false
      expect(node['gitlab']['postgresql']['enable']).to eq false
      expect(node['gitlab']['mailroom']['enable']).to eq false
    end
  end

  context 'with roles' do
    context 'when redis_sentinel_role is enabled' do
      before do
        stub_gitlab_rb(
          redis_sentinel_role: {
            enable: true
          }
        )
      end

      it_behaves_like 'regular services are disabled'

      it 'only sentinel is enabled' do
        expect(node['gitlab']['sentinel']['enable']).to eq true
        expect(node['gitlab']['redis']['enable']).to eq false
      end

      context 'when redis_sentinel_role is enabled with redis_master_role' do
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
          expect(node['gitlab']['redis']['enable']).to eq true
        end
      end

      context 'when redis_sentinel_role is enabled with redis_slave_role' do
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
          expect(node['gitlab']['redis']['enable']).to eq true
        end
      end
    end

    context 'when redis_master_role is enabled' do
      before do
        stub_gitlab_rb(
          redis_master_role: {
            enable: true
          }
        )
      end

      it_behaves_like 'regular services are disabled'

      it 'only redis is enabled' do
        expect(node['gitlab']['redis']['enable']).to eq true
        expect(node['gitlab']['sentinel']['enable']).to eq false
      end
    end

    context 'when redis_slave_role is enabled' do
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
        expect(node['gitlab']['redis']['enable']).to eq true
        expect(node['gitlab']['sentinel']['enable']).to eq false
      end
    end

    context 'when redis_master_role and redis_slave_role are enabled' do
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
