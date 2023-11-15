require 'chef_helper'

RSpec.describe 'database_objects' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(database_objects postgresql_extension)).converge('gitlab::config', 'test_postgresql::postgresql_database_objects') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe 'create' do
    context 'by default' do
      it 'creates main database' do
        expect(chef_run).to create_postgresql_database('gitlabhq_production')
      end
    end

    context 'when additional databases are specified' do
      context 'on same host as that of main database' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              databases: {
                ci: {
                  enable: true,
                  db_database: 'gitlabhq_production_ci'
                }
              }
            }
          )
        end

        it 'creates specified databases in addition to main database' do
          %w[gitlabhq_production_ci gitlabhq_production].each do |db|
            expect(chef_run).to create_postgresql_database(db)
          end
        end
      end

      context 'on a different host than that of main database' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              databases: {
                ci: {
                  enable: true,
                  db_database: 'gitlabhq_production_ci',
                  db_host: 'different.db.host'
                }
              }
            }
          )
        end

        it 'creates only main database and not CI database' do
          expect(chef_run).to create_postgresql_database('gitlabhq_production')
          expect(chef_run).not_to create_postgresql_database('gitlabhq_production_ci')
        end
      end
    end

    context 'when Geo database is specified' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            databases: {
              ci: {
                enable: true,
                db_database: 'gitlabhq_production_ci'
              }
            }
          },
          geo_secondary_role: {
            enable: true
          }
        )
      end

      it 'creates specified databases in addition to main database except geo' do
        expect(chef_run).to create_postgresql_database('gitlabhq_production')
        expect(chef_run).to create_postgresql_database('gitlabhq_production_ci')

        expect(chef_run).not_to create_postgresql_database('gitlabhq_geo_production')
      end
    end
  end
end
