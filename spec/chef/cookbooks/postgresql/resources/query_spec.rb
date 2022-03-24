require 'chef_helper'

RSpec.describe 'postgresql_query' do
  let(:runner) { ChefSpec::SoloRunner.new(step_into: %w(postgresql_query)) }

  before do
    allow_any_instance_of(PgHelper).to receive(:is_ready?).and_return(true)
    allow_any_instance_of(GeoPgHelper).to receive(:is_ready?).and_return(true)
  end

  context 'run' do
    let(:chef_run) { runner.converge('test_postgresql::postgresql_query_run') }

    context 'when service is up' do
      before do
        allow_any_instance_of(PgHelper).to receive(:is_offline_or_readonly?).and_return(false)
        allow_any_instance_of(GeoPgHelper).to receive(:is_offline_or_readonly?).and_return(false)
      end

      it 'runs the query with correct service' do
        expect(chef_run).to run_execute('create schema (postgresql)').with(
          command: %(/opt/gitlab/bin/gitlab-psql -d omnibus_test -c "CREATE SCHEMA example AUTHORIZATION foobar;")
        )

        expect(chef_run).to run_execute('create schema (geo-postgresql)').with(
          command: %(/opt/gitlab/bin/gitlab-geo-psql -d omnibus_test -c "CREATE SCHEMA example AUTHORIZATION foobar;")
        )
      end
    end

    context 'when service is offline' do
      before do
        allow_any_instance_of(PgHelper).to receive(:is_offline_or_readonly?).and_return(true)
        allow_any_instance_of(GeoPgHelper).to receive(:is_offline_or_readonly?).and_return(true)
      end

      it 'does not run the query' do
        expect(chef_run).not_to run_execute('create example schema (postgresql)')
        expect(chef_run).not_to run_execute('create example schema (geo-postgresql)')
      end
    end
  end
end
