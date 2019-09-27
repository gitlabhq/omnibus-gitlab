require 'chef_helper'

describe 'postgresql_config' do
  let(:runner) do
    ChefSpec::SoloRunner.new(step_into: %w(postgresql_config)) do |node|
      node.normal['postgresql']['data_dir'] = '/fakedir'
    end
  end

  context 'create' do
    let(:chef_run) { runner.converge('test_postgresql::postgresql_config') }

    before do
      allow_any_instance_of(PgHelper).to receive(:postgresql_user).and_return('fakeuser')
    end

    context 'default settings' do
      it 'creates the files' do
        expect(chef_run).to render_file('/fakedir/postgresql.conf')
        expect(chef_run).to render_file('/fakedir/runtime.conf')
        expect(chef_run).to render_file('/fakedir/pg_hba.conf')
        expect(chef_run).to render_file('/fakedir/pg_ident.conf')
      end
    end
  end
end
