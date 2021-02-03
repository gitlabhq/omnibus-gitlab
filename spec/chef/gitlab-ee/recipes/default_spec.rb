require 'chef_helper'

RSpec.describe 'gitlab-ee::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'postgresql is enabled' do
    context 'pgbouncer will not connect to postgresql' do
      it 'should always include the pgbouncer_user recipe' do
        expect(chef_run).to include_recipe('pgbouncer::user')
      end
    end

    context 'pgbouncer will connect to postgresql' do
      before do
        stub_gitlab_rb(
          {
            postgresql: {
              pgbouncer_user_password: 'fakepassword'
            }
          }
        )
      end

      it 'should include the pgbouncer_user recipe' do
        expect(chef_run).to include_recipe('pgbouncer::user')
      end
    end
  end
end
