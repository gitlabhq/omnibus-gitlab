require 'chef_helper'

RSpec.describe PgbouncerHelper do
  let(:chef_run) { converge_config(is_ee: true) }
  subject { described_class.new(chef_run.node) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe '#running?' do
    cached(:chef_run) { converge_config(is_ee: true) }

    it 'returns true when pgbouncer is running' do
      stub_service_success_status('pgbouncer', true)

      expect(subject.running?).to be_truthy
    end

    it 'returns false when pgbouncer is not running' do
      stub_service_success_status('pgbouncer', false)

      expect(subject.running?).to be_falsey
    end
  end

  describe '#pg_auth_type_prefix' do
    using RSpec::Parameterized::TableSyntax
    where(:type, :prefix) do
      'md5' | 'md5'
      'scram-sha-256' | 'SCRAM-SHA-256$'
      'MD5' | 'md5'
      'SCRAM-SHA-256' | 'SCRAM-SHA-256$'
      'plain' | nil
      'ScRaM-ShA-256' | 'SCRAM-SHA-256$'
    end

    with_them do
      it 'responds to default values' do
        expect(subject.pg_auth_type_prefix(type)).to eq(prefix)
      end
    end
  end

  describe '#pgbouncer_admin_config' do
    context 'by default' do
      it 'by default' do
        expect(subject.pgbouncer_admin_config).to eq('user=pgbouncer dbname=pgbouncer sslmode=disable port=6432 host=/var/opt/gitlab/pgbouncer')
      end
    end

    context 'with custom sttings' do
      before do
        stub_gitlab_rb(
          postgresql: {
            pgbouncer_user: 'tester',
          },
          pgbouncer: {
            listen_port: 1234,
            data_directory: '/tmp'
          }
        )
      end

      it 'uses custom settings' do
        expect(subject.pgbouncer_admin_config).to eq('user=tester dbname=pgbouncer sslmode=disable port=1234 host=/tmp')
      end
    end
  end

  describe '#pg_auth_users' do
    context 'by default' do
      it 'by default' do
        expect(subject.pg_auth_users).to be_empty
      end
    end

    context 'with users' do
      before do
        stub_gitlab_rb(
          pgbouncer: {
            users: {
              fakeuser: {
                password: 'fakepassword'
              }
            }
          }
        )
      end

      it 'returns a hash' do
        expect(subject.pg_auth_users).to eq 'fakeuser' => { 'password' => 'fakepassword' }
      end
    end

    context 'with databases' do
      before do
        stub_gitlab_rb(
          pgbouncer: {
            databases: {
              fakedb: {
                user: 'fakeuser',
                password: 'fakepassword'
              }
            }
          }
        )
      end

      it 'returns a hash' do
        expect(subject.pg_auth_users).to eq 'fakeuser' => { 'password' => 'fakepassword' }
      end
    end

    context 'with both' do
      before do
        stub_gitlab_rb(
          pgbouncer: {
            databases: {
              fakedb: {
                user: 'fakedbuser',
                password: 'fakepassword'
              }
            },
            users: {
              fakeusersuser: {
                password: 'fakepassword'
              }
            }
          }
        )
      end

      it 'should merge both' do
        expected = {
          'fakeusersuser' => { 'password' => 'fakepassword' }, 'fakedbuser' => { 'password' => 'fakepassword' }
        }
        expect(subject.pg_auth_users).to eq expected
      end
    end

    context 'with multiple databases' do
      before do
        stub_gitlab_rb(
          pgbouncer: {
            databases: {
              fakedb_one: {
                user: 'fakeuser',
                password: 'fakepassword'
              },
              fakedb_two: {
                user: 'fakeuser',
                password: 'fakepassword'
              }
            }
          }
        )
      end

      it 'should only have one entry' do
        expect(subject.pg_auth_users).to eq 'fakeuser' => { 'password' => 'fakepassword' }
      end
    end
  end
end
