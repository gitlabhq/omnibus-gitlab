require_relative '../../../../files/gitlab-cookbooks/gitlab-ee/libraries/fdw_helper.rb'
require 'chef_helper'

describe FdwHelper do
  let(:chef_run) { converge_config(is_ee: true) }
  subject { described_class.new(chef_run.node) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe '#fdw_can_refresh?' do
    # `#fdw_can_refresh?` returns true with these configs and stubs
    let(:postgresql_config) do
      {
        enable: true,
        sql_user: 'mygeodbuser'
      }
    end
    let(:geo_secondary_config) do
      {
        enable: true,
        db_database: 'gitlab_geodb',
        db_fdw: true
      }
    end
    let(:gitlab_rails_config) do
      {
        db_host: '10.0.0.1',
        db_port: 5430,
        db_username: 'mydbuser',
        db_database: 'gitlab_myorg',
        db_password: 'custompass'
      }
    end
    let(:pg_helper_stubs) { { is_managed_and_offline?: false, database_empty?: false } }
    let(:geo_pg_helper_stubs) { { is_offline_or_readonly?: false, schema_exists?: true } }
    let(:gitlab_geo_helper_stubs) { { geo_database_configured?: true } }
    let(:helper_stubs) do
      {
        pg_helper: pg_helper_stubs,
        geo_pg_helper: geo_pg_helper_stubs,
        gitlab_geo_helper: gitlab_geo_helper_stubs
      }
    end
    let(:foreign_schema_tables_match) { false }

    before do
      stub_gitlab_rb(geo_postgresql: postgresql_config,
                     geo_secondary: geo_secondary_config,
                     gitlab_rails: gitlab_rails_config)

      helper_stubs.each do |helper_method, stubs|
        fake_helper = double(stubs)
        allow(subject).to receive(helper_method).and_return(fake_helper)
      end

      allow(subject).to receive(:foreign_schema_tables_match?).and_return(foreign_schema_tables_match)
    end

    context 'when fdw has all required states to be refreshed' do
      it 'returns true' do
        expect(subject.fdw_can_refresh?).to be_truthy
      end
    end

    context 'when fdw is not enabled' do
      let(:geo_secondary_config) do
        {
          enable: true,
          db_database: 'gitlab_geodb',
          db_fdw: false
        }
      end

      it 'returns false' do
        expect(subject.fdw_can_refresh?).to be_falsey
      end
    end

    context 'when geo database is not configured' do
      let(:gitlab_geo_helper_stubs) { { geo_database_configured?: false } }

      it 'returns false' do
        expect(subject.fdw_can_refresh?).to be_falsey
      end
    end

    context 'when postgres is managed and is offline' do
      let(:pg_helper_stubs) { { is_managed_and_offline?: true, database_empty?: false } }

      it 'returns false' do
        expect(subject.fdw_can_refresh?).to be_falsey
      end
    end

    context 'when the FDW database is empty' do
      let(:pg_helper_stubs) { { is_managed_and_offline?: false, database_empty?: true } }

      it 'returns false' do
        expect(subject.fdw_can_refresh?).to be_falsey
      end
    end

    context 'when the tracking database is offline, or is read-only' do
      let(:geo_pg_helper_stubs) { { is_offline_or_readonly?: true, schema_exists?: true } }

      it 'returns false' do
        expect(subject.fdw_can_refresh?).to be_falsey
      end
    end

    context 'when the tracking database schema does not exist' do
      let(:geo_pg_helper_stubs) { { is_offline_or_readonly?: false, schema_exists?: false } }

      it 'returns false' do
        expect(subject.fdw_can_refresh?).to be_falsey
      end
    end

    context 'when the foreign schema tables already match' do
      let(:foreign_schema_tables_match) { true }

      it 'returns false' do
        expect(subject.fdw_can_refresh?).to be_falsey
      end
    end
  end

  describe '#pg_hba_entries' do
    before do
      stub_gitlab_rb(
        geo_postgresql: {
          enable: true,
          sql_user: 'mygeodbuser'
        },
        geo_secondary: {
          enable: true,
          db_database: 'gitlab_geodb',
          db_fdw: true
        },
        gitlab_rails: {
          db_host: '10.0.0.1',
          db_port: 5430,
          db_username: 'mydbuser',
          db_database: 'gitlab_myorg',
          db_password: 'custompass'
        },
        postgresql: {
          md5_auth_cidr_addresses: %w(10.0.0.1/32 10.0.0.2/32)
        }
      )
    end

    it 'returns array of hashes with expected keys' do
      pg_hba_entries = [
        {
          type: 'host',
          database: 'gitlab_myorg',
          user: 'mydbuser',
          cidr: '10.0.0.1/32',
          method: 'md5'
        },
        {
          type: 'host',
          database: 'gitlab_myorg',
          user: 'mydbuser',
          cidr: '10.0.0.2/32',
          method: 'md5'
        }
      ]
      expect(subject.pg_hba_entries).to eq(pg_hba_entries)
    end
  end

  describe '#foreign_schema_tables_match?' do
    let(:example_output) do
      # This looks like actual output. The content varies by GitLab version,
      # but that does not matter for these tests.
      <<~OUTPUT
        abuse_reports|created_at|timestamp without time zone
        abuse_reports|id|integer
        abuse_reports|message|text
        abuse_reports|updated_at|timestamp without time zone
        abuse_reports|user_id|integer
        alerts_service_data|created_at|timestamp with time zone
        alerts_service_data|encrypted_token|character varying
      OUTPUT
    end

    before do
      expect(subject).to receive(:retrieve_gitlab_schema_tables).and_return(gitlab_schema_output)
      expect(subject).to receive(:retrieve_foreign_schema_tables).and_return(foreign_schema_output)
    end

    context 'when both schemas have exactly the same content' do
      let(:gitlab_schema_output) { example_output }
      let(:foreign_schema_output) { example_output }

      it 'returns true' do
        expect(subject.foreign_schema_tables_match?).to be_truthy
      end
    end

    context 'when the schemas have different content' do
      context 'when a column was added' do
        # some_new_column was added
        let(:gitlab_schema_output) do
          <<~OUTPUT
            abuse_reports|created_at|timestamp without time zone
            abuse_reports|id|integer
            abuse_reports|message|text
            abuse_reports|some_new_column|boolean
            abuse_reports|updated_at|timestamp without time zone
            abuse_reports|user_id|integer
            alerts_service_data|created_at|timestamp with time zone
            alerts_service_data|encrypted_token|character varying
          OUTPUT
        end
        let(:foreign_schema_output) { example_output }

        it 'returns false' do
          expect(subject.foreign_schema_tables_match?).to be_falsey
        end
      end

      context 'when a column was dropped' do
        # message was dropped
        let(:gitlab_schema_output) do
          <<~OUTPUT
            abuse_reports|created_at|timestamp without time zone
            abuse_reports|id|integer
            abuse_reports|updated_at|timestamp without time zone
            abuse_reports|user_id|integer
            alerts_service_data|created_at|timestamp with time zone
            alerts_service_data|encrypted_token|character varying
          OUTPUT
        end
        let(:foreign_schema_output) { example_output }

        it 'returns false' do
          expect(subject.foreign_schema_tables_match?).to be_falsey
        end
      end

      context 'when a column was renamed' do
        # message => message_renamed
        let(:gitlab_schema_output) do
          <<~OUTPUT
            abuse_reports|created_at|timestamp without time zone
            abuse_reports|id|integer
            abuse_reports|message_renamed|text
            abuse_reports|updated_at|timestamp without time zone
            abuse_reports|user_id|integer
            alerts_service_data|created_at|timestamp with time zone
            alerts_service_data|encrypted_token|character varying
          OUTPUT
        end
        let(:foreign_schema_output) { example_output }

        it 'returns false' do
          expect(subject.foreign_schema_tables_match?).to be_falsey
        end
      end

      context 'when a column type was changed' do
        # abuse_reports.id int => bigint
        let(:gitlab_schema_output) do
          <<~OUTPUT
            abuse_reports|created_at|timestamp without time zone
            abuse_reports|id|bigint
            abuse_reports|message|text
            abuse_reports|updated_at|timestamp without time zone
            abuse_reports|user_id|integer
            alerts_service_data|created_at|timestamp with time zone
            alerts_service_data|encrypted_token|character varying
          OUTPUT
        end
        let(:foreign_schema_output) { example_output }

        it 'returns false' do
          expect(subject.foreign_schema_tables_match?).to be_falsey
        end
      end

      context 'when a table was added' do
        # Added table "added_this_table"
        let(:gitlab_schema_output) do
          <<~OUTPUT
            abuse_reports|created_at|timestamp without time zone
            abuse_reports|id|bigint
            abuse_reports|message|text
            abuse_reports|updated_at|timestamp without time zone
            abuse_reports|user_id|integer
            added_this_table|id|integer
            alerts_service_data|created_at|timestamp with time zone
            alerts_service_data|encrypted_token|character varying
          OUTPUT
        end
        let(:foreign_schema_output) { example_output }

        it 'returns false' do
          expect(subject.foreign_schema_tables_match?).to be_falsey
        end
      end

      context 'when a table was dropped' do
        # Dropped abuse_reports
        let(:gitlab_schema_output) do
          <<~OUTPUT
            alerts_service_data|created_at|timestamp with time zone
            alerts_service_data|encrypted_token|character varying
          OUTPUT
        end
        let(:foreign_schema_output) { example_output }

        it 'returns false' do
          expect(subject.foreign_schema_tables_match?).to be_falsey
        end
      end

      context 'when a table was renamed' do
        # abuse_reports => abuse_reports_renamed
        let(:gitlab_schema_output) do
          <<~OUTPUT
            abuse_reports_renamed|created_at|timestamp without time zone
            abuse_reports_renamed|id|bigint
            abuse_reports_renamed|message|text
            abuse_reports_renamed|updated_at|timestamp without time zone
            abuse_reports_renamed|user_id|integer
            alerts_service_data|created_at|timestamp with time zone
            alerts_service_data|encrypted_token|character varying
          OUTPUT
        end
        let(:foreign_schema_output) { example_output }

        it 'returns false' do
          expect(subject.foreign_schema_tables_match?).to be_falsey
        end
      end
    end
  end
end
