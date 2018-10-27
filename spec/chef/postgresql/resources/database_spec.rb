require 'chef_helper'

describe 'postgresql_database' do
  let(:runner) do
    ChefSpec::SoloRunner.new(step_into: %w(postgresql_database)) do |node|
      # unix_socket_directory is normally conditionally set in postgresql::enable
      # which is not executed as part of this spec
      node.normal['postgresql']['unix_socket_directory'] = '/var/opt/gitlab/postgresql'
    end
  end

  context 'create' do
    let(:chef_run) { runner.converge('test_postgresql::postgresql_database_create') }

    context 'server is running' do
      before do
        allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
      end

      context 'database does not already exist' do
        before do
          allow_any_instance_of(PgHelper).to receive(:database_exists?).and_return(false)
        end

        it 'creates a database' do
          expect(chef_run).to run_execute('create database example').with(
            command: %(/opt/gitlab/embedded/bin/createdb --port 5432 -h /var/opt/gitlab/postgresql -O gitlab example),
            user: 'gitlab-psql'
          )
        end

        context 'with non-default options' do
          let(:chef_run) { runner.converge('test_postgresql::postgresql_database_create_with_options') }

          it 'creates with the correct options set' do
            expect(chef_run).to run_execute('create database fakedb').with(
              command: %(/opt/gitlab/embedded/bin/createdb --port 9999 -h /fake/dir -O fakeuser fakedb)
            )
          end
        end
      end

      context 'database already exists' do
        before do
          allow_any_instance_of(PgHelper).to receive(:database_exists?).with('example').and_return(true)
        end

        it 'does nothing' do
          expect(chef_run).not_to run_execute('create database example')
        end
      end
    end

    context 'server is not running' do
      before do
        allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(false)
      end

      it 'does nothing' do
        expect(chef_run).not_to run_execute('create database example')
      end
    end
  end
end
