require 'chef_helper'

RSpec.describe 'postgresql_config' do
  let(:runner) do
    ChefSpec::SoloRunner.new(step_into: %w(postgresql_config)) do |node|
      node.normal['postgresql']['dir'] = '/fakedir'
      node.normal['patroni']['dir'] = '/patronifakedir'
    end
  end

  let(:chef_run) { runner.converge('gitlab::config', 'test_postgresql::postgresql_config') }

  before do
    allow_any_instance_of(PgHelper).to receive(:postgresql_user).and_return('fakeuser')
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'create' do
    context 'default settings' do
      it 'creates the files' do
        expect(chef_run).to render_file('/fakedir/data/postgresql.conf')
        expect(chef_run).to render_file('/fakedir/data/runtime.conf')
        expect(chef_run).to render_file('/fakedir/data/pg_hba.conf')
        expect(chef_run).to render_file('/fakedir/data/pg_ident.conf')
      end
    end

    context 'when patroni is enabled' do
      before do
        stub_gitlab_rb(
          patroni: {
            enable: true
          }
        )
      end

      it 'creates the files' do
        expect(chef_run).to render_file('/patronifakedir/data/postgresql.base.conf')
        expect(chef_run).to render_file('/patronifakedir/data/runtime.conf')
        expect(chef_run).to render_file('/patronifakedir/data/pg_hba.conf')
        expect(chef_run).to render_file('/patronifakedir/data/pg_ident.conf')
      end
    end
  end
end
