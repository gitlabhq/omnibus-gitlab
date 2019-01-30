require 'chef_helper'

describe 'postgresql_query' do
  let(:runner) { ChefSpec::SoloRunner.new(step_into: %w(postgresql_extension)) }

  context 'run' do
    let(:chef_run) { runner.converge('test_postgresql::postgresql_extension_enable') }

    context 'when extension can be enabled' do
      before do
        allow_any_instance_of(PgHelper).to receive(:extension_can_be_enabled?).with('foobar', 'lorem').and_return(true)
      end

      it 'runs the query to enable extension' do
        expect(chef_run).to run_postgresql_query('enable foobar extension').with(
          query: %(CREATE EXTENSION IF NOT EXISTS foobar),
          db_name: 'lorem'
        )
      end
    end

    context 'when extension can not be enabled' do
      before do
        allow_any_instance_of(PgHelper).to receive(:extension_can_be_enabled?).with('foobar', 'lorem').and_return(false)
      end

      it 'does not run the query to enable extension' do
        expect(chef_run).not_to run_postgresql_query('enable foobar extension')
      end
    end
  end
end
