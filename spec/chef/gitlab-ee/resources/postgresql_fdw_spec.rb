require 'chef_helper'

RSpec.describe 'postgresql_fdw' do
  let(:runner) do
    ChefSpec::SoloRunner.new(step_into: %w(postgresql_fdw))
  end

  context 'create' do
    let(:chef_run) { runner.converge('test_gitlab_ee::postgresql_fdw_create') }

    context 'service is online' do
      before do
        allow_any_instance_of(PgHelper).to receive(:is_offline_or_readonly?).and_return(false)
      end

      describe 'postgres_fdw extension' do
        context 'enabled already' do
          it 'does not attempt to enable extension' do
            allow_any_instance_of(PgHelper).to receive(:extension_enabled?).and_call_original
            allow_any_instance_of(PgHelper).to receive(:extension_enabled?).with('postgres_fdw', 'foobar').and_return(true)
            expect(chef_run).not_to run_postgresql_query('enable postgres_fdw extension on foobar')
          end
        end

        context 'not enabled already' do
          before do
            allow_any_instance_of(PgHelper).to receive(:extension_enabled?).and_call_original
            allow_any_instance_of(PgHelper).to receive(:extension_enabled?).with('postgres_fdw', 'foobar').and_return(false)
          end

          it 'enables extension' do
            expect(chef_run).to run_postgresql_query('enable postgres_fdw extension on foobar').with(
              db_name: 'foobar',
              query: 'CREATE EXTENSION IF NOT EXISTS postgres_fdw;'
            )
          end
        end
      end

      describe 'fdw server' do
        describe 'creation' do
          context 'does not exist already' do
            before do
              allow_any_instance_of(PgHelper).to receive(:fdw_server_exists?).and_return(false)
            end

            it 'creates fdw server' do
              expect(chef_run).to run_postgresql_query('create fdw gitlab_secondary on foobar').with(
                query: "CREATE SERVER gitlab_secondary FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '127.0.0.1', port '1234', dbname 'lorem');",
                db_name: 'foobar'
              )
            end
          end

          context 'exist already' do
            before do
              allow_any_instance_of(PgHelper).to receive(:fdw_server_exists?).and_return(true)
            end

            it 'does not create fdw server' do
              expect(chef_run).not_to run_postgresql_query('create fdw gitlab_secondary on foobar')
            end
          end
        end

        describe 'update' do
          context 'when options are changed' do
            before do
              allow_any_instance_of(PgHelper).to receive(:fdw_server_options_changed?).and_return(true)
              allow_any_instance_of(PgHelper).to receive(:fdw_server_exists?).and_return(true)
            end

            it 'updates fdw server' do
              expect(chef_run).to run_postgresql_query('update fdw gitlab_secondary on foobar').with(
                query: "ALTER SERVER gitlab_secondary OPTIONS (SET host '127.0.0.1', SET port '1234', SET dbname 'lorem');",
                db_name: 'foobar'
              )
            end
          end

          context 'when options are not changed' do
            before do
              allow_any_instance_of(PgHelper).to receive(:fdw_server_options_changed?).and_return(false)
            end

            it 'does not update fdw server' do
              expect(chef_run).not_to run_postgresql_query('update fdw gitlab_secondary on foobar')
            end
          end
        end
      end
    end

    context 'service is offline' do
      before do
        allow_any_instance_of(PgHelper).to receive(:is_offline_or_readonly?).and_return(true)
      end

      it 'does not attempt to enable extension' do
        expect(chef_run).not_to run_postgresql_query('enable postgres_fdw extension on foobar')
      end

      it 'does not create fdw server' do
        expect(chef_run).not_to run_postgresql_query('create fdw gitlab_secondary on foobar')
      end

      it 'does not update fdw server' do
        expect(chef_run).not_to run_postgresql_query('update fdw gitlab_secondary on foobar')
      end
    end
  end

  context 'delete' do
    let(:chef_run) { runner.converge('test_gitlab_ee::postgresql_fdw_delete') }

    context 'service is online' do
      before do
        allow_any_instance_of(PgHelper).to receive(:is_offline_or_readonly?).and_return(false)
        allow_any_instance_of(PgHelper).to receive(:fdw_server_exists?).and_return(true)
      end

      it 'drops fdw server' do
        expect(chef_run).to run_postgresql_query('drop fdw gitlab_secondary on foobar').with(
          query: "DROP SERVER gitlab_secondary CASCADE;",
          db_name: 'foobar'
        )
      end
    end

    context 'service is offline' do
      before do
        allow_any_instance_of(PgHelper).to receive(:is_offline_or_readonly?).and_return(false)
      end

      it 'does not attempt to drop fdw server' do
        expect(chef_run).not_to run_postgresql_query('drop fdw gitlab_secondary on foobar')
      end
    end

    context 'fdw server does not exist' do
      before do
        allow_any_instance_of(PgHelper).to receive(:is_offline_or_readonly?).and_return(false)
      end

      it 'does not attempt to drop fdw server' do
        expect(chef_run).not_to run_postgresql_query('drop fdw gitlab_secondary on foobar')
      end
    end
  end
end
