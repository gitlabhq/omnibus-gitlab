require 'chef_helper'

describe 'gitlab::redis' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(sentinel_service runit_service)).converge('gitlab-ee::default') }
  let(:redis_master_ip) { '1.1.1.1' }
  let(:redis_announce_ip) { '10.10.10.10' }
  let(:redis_master_password) { 'blahblahblah' }

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

      it_behaves_like 'enabled runit service', 'sentinel', 'root', 'root'
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
            announce_ip: redis_announce_ip,
            master_password: redis_master_password
          }
        )
      end
      it 'creates redis user and group' do
        expect(chef_run).to create_account('user and group for sentinel').with(username: 'foo', groupname: 'bar')
      end

      it_behaves_like 'enabled runit service', 'sentinel', 'root', 'root'
    end
  end
end
