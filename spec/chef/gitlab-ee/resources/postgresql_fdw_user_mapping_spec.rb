require 'chef_helper'

describe 'postgresql_fdw_user_mapping' do
  let(:runner) do
    ChefSpec::SoloRunner.new(step_into: %w(postgresql_fdw_user_mapping))
  end

  context 'create' do
    let(:chef_run) { runner.converge('test_gitlab_ee::postgresql_fdw_user_mapping_create') }

    context 'service is online' do
      before do
        allow_any_instance_of(PgHelper).to receive(:is_offline_or_readonly?).and_return(false)
      end

      describe 'postgres_fdw mapping' do
        describe 'creation' do
          context 'fdw server exists and mapping does not exist already' do
            before do
              allow_any_instance_of(PgHelper).to receive(:fdw_server_exists?).and_return(true)
              allow_any_instance_of(PgHelper).to receive(:fdw_user_mapping_exists?).and_return(false)
            end

            it 'creates mapping' do
              expect(chef_run).to run_postgresql_query('create mapping for randomuser at gitlab_secondary').with(
                query: "CREATE USER MAPPING FOR randomuser SERVER gitlab_secondary OPTIONS (user 'externaluser', password 'externalpassword');",
                db_name: 'foobar'
              )
            end
          end

          context 'fdw server exists and mapping exist already' do
            before do
              allow_any_instance_of(PgHelper).to receive(:fdw_server_exists?).and_return(true)
              allow_any_instance_of(PgHelper).to receive(:fdw_user_mapping_exists?).and_return(true)
            end

            it 'does not create mapping' do
              expect(chef_run).not_to run_postgresql_query('create mapping for randomuser at gitlab_secondary')
            end
          end
        end

        describe 'update' do
          context 'fdw server and mapping exists and mapping changed' do
            before do
              allow_any_instance_of(PgHelper).to receive(:fdw_server_exists?).and_return(true)
              allow_any_instance_of(PgHelper).to receive(:fdw_user_mapping_exists?).and_return(true)
              allow_any_instance_of(PgHelper).to receive(:fdw_user_mapping_changed?).and_return(true)
            end

            it 'updates mapping' do
              expect(chef_run).to run_postgresql_query('update mapping for randomuser at gitlab_secondary').with(
                query: "ALTER USER MAPPING FOR randomuser SERVER gitlab_secondary OPTIONS (SET user 'externaluser', ADD password 'externalpassword');",
                db_name: 'foobar'
              )
            end
          end

          context 'fdw server and mapping exists but mapping not changed' do
            before do
              allow_any_instance_of(PgHelper).to receive(:fdw_server_exists?).and_return(true)
              allow_any_instance_of(PgHelper).to receive(:fdw_user_mapping_exists?).and_return(true)
              allow_any_instance_of(PgHelper).to receive(:fdw_user_mapping_changed?).and_return(false)
            end

            it 'does not update mapping' do
              expect(chef_run).not_to run_postgresql_query('update mapping for randomuser at gitlab_secondary')
            end
          end
        end
      end

      describe 'usage privilege' do
        context 'fdw server exists and user does not have server privilege' do
          before do
            allow_any_instance_of(PgHelper).to receive(:fdw_server_exists?).and_return(true)
            allow_any_instance_of(PgHelper).to receive(:fdw_user_has_server_privilege?).and_return(false)
          end

          it 'grants usage privileges correctly' do
            expect(chef_run).to run_postgresql_query('grant usage on foreign server gitlab_secondary to randomuser').with(
              query: 'GRANT USAGE ON FOREIGN SERVER gitlab_secondary TO randomuser;',
              db_name: 'foobar'
            )
          end
        end

        context 'fdw server exists and user already has server privilege' do
          before do
            allow_any_instance_of(PgHelper).to receive(:fdw_server_exists?).and_return(true)
            allow_any_instance_of(PgHelper).to receive(:fdw_user_has_server_privilege?).and_return(true)
          end

          it 'does not attempt to grant usage privileges' do
            expect(chef_run).not_to run_postgresql_query('grant usage on foreign server gitlab_secondary to randomuser')
          end
        end
      end
    end

    context 'service is offline' do
      before do
        allow_any_instance_of(PgHelper).to receive(:is_offline_or_readonly?).and_return(true)
      end

      it 'does not create mapping' do
        expect(chef_run).not_to run_postgresql_query('create mapping for randomuser at gitlab_secondary')
      end

      it 'does not update mapping' do
        expect(chef_run).not_to run_postgresql_query('update mapping for randomuser at gitlab_secondary')
      end

      it 'does not attempt to grant usage privileges' do
        expect(chef_run).not_to run_postgresql_query('grant usage on foreign server gitlab_secondary to randomuser')
      end
    end
  end
end
