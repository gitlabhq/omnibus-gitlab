require 'chef_helper'

describe 'postgresql_schema' do
  let(:runner) { ChefSpec::SoloRunner.new(step_into: %w(postgresql_schema)) }

  context 'create' do
    let(:chef_run) { runner.converge('test_postgresql::postgresql_schema_create') }

    context 'server is running' do
      before do
        allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
        allow_any_instance_of(PgHelper).to receive(:is_standby?).and_return(false)
      end

      it 'creates schema' do
        expect(chef_run).to run_postgresql_query('create example schema on omnibus_gitlab_test').with(
          db_name: 'omnibus_gitlab_test'
        )
      end

      context 'schema already exists' do
        before do
          allow_any_instance_of(PgHelper).to receive(:schema_exists?).and_return(true)
        end

        it 'does not try to create schema again' do
          expect(chef_run).not_to run_postgresql_query('create example schema on omnibus_gitlab_test')
        end

        context 'when schema owner is different' do
          before do
            allow_any_instance_of(PgHelper).to receive(:schema_owner?).and_return(false)
          end

          it 'tries to update schema' do
            expect(chef_run).to run_postgresql_query('modify example schema owner on omnibus_gitlab_test')
          end
        end

        context 'when schema owner is the same' do
          before do
            allow_any_instance_of(PgHelper).to receive(:schema_owner?).and_return(true)
          end

          it 'tries to update schema' do
            expect(chef_run).not_to run_postgresql_query('modify example schema owner on omnibus_gitlab_test')
          end
        end
      end
    end
  end
end
