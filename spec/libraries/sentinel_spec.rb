# This spec is to test the Sentinel helper and whether the values parsed
# are the ones we expect
require 'chef_helper'

RSpec.describe 'Sentinel' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::config') }
  let(:node) { chef_run.node }
  subject { ::Sentinel }
  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context '.parse_variables' do
    context 'When sentinel is enabled' do
      before do
        stub_gitlab_rb(
          redis_sentinel_role: {
            enable: true,
          }
        )
      end
      it 'delegates to parse_sentinel_settings' do
        expect(subject).to receive(:parse_sentinel_settings)

        subject.parse_variables
      end

      context 'when redis announce_ip is defined' do
        let(:redis_master_ip) { '1.1.1.1' }
        let(:redis_announce_ip) { '10.10.10.10' }
        before do
          stub_gitlab_rb(
            redis: {
              master_ip: redis_master_ip,
              announce_ip: redis_announce_ip
            }
          )
        end

        it 'Sentinel announce_ip is autofilled based on redis announce_ip' do
          expect(node['gitlab']['sentinel']['announce_ip']).to eq redis_announce_ip

          subject.parse_sentinel_settings
        end
      end

      context 'when redis announce_port is defined' do
        let(:redis_announce_port) { 6370 }
        let(:sentinel_port) { 26370 }
        before do
          stub_gitlab_rb(
            sentinel: {
              port: sentinel_port
            },
            redis: {
              announce_port: redis_announce_port
            }
          )
        end
        it 'Sentinel announce_port is autofilled based on sentinel port' do
          expect(node['gitlab']['sentinel']['announce_port']).to eq sentinel_port

          subject.parse_sentinel_settings
        end
      end
    end
  end
end
