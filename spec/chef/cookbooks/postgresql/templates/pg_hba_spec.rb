require 'chef_helper'

RSpec.describe 'pg_hba.conf.erb template' do
  let(:chef_runner) do
    ChefSpec::SoloRunner.new(step_into: %w(postgresql_config)) do |node|
      node.normal['postgresql']['enable'] = true
      node.normal['postgresql']['dir'] = '/fakedir'
    end
  end

  let(:chef_run) do
    chef_runner.converge('gitlab-ee::default')
  end

  let(:template_path) { '/fakedir/data/pg_hba.conf' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow(Gitlab).to receive(:[]).with('node') { chef_runner.node }
  end

  context 'when registry backup and restore users are configured' do
    before do
      stub_gitlab_rb(
        postgresql: {
          registry: {
            database_backup_username: 'registry_backup',
            database_backup_password: 'md5backuppassword',
            database_restore_username: 'registry_restore',
            database_restore_password: 'md5restorepassword',
            dbname: 'registry'
          }
        }
      )
    end

    it 'adds backup user authentication entry restricted to registry database' do
      expect(chef_run).to render_file(template_path)
        .with_content(/^local\s+registry\s+registry_backup\s+md5$/)
    end

    it 'adds restore user authentication entry restricted to registry database' do
      expect(chef_run).to render_file(template_path)
        .with_content(/^local\s+registry\s+registry_restore\s+md5$/)
    end

    it 'places backup and restore user entries before the general local entry' do
      expect(chef_run).to render_file(template_path)
        .with_content(/local\s+registry\s+registry_backup\s+md5.*local\s+all\s+all\s+peer\s+map=gitlab/m)
      expect(chef_run).to render_file(template_path)
        .with_content(/local\s+registry\s+registry_restore\s+md5.*local\s+all\s+all\s+peer\s+map=gitlab/m)
    end

    context 'with md5_auth_cidr_addresses configured' do
      before do
        stub_gitlab_rb(
          postgresql: {
            md5_auth_cidr_addresses: ['10.0.0.0/8', '192.168.1.0/24'],
            registry: {
              database_backup_username: 'registry_backup',
              database_backup_password: 'md5backuppassword',
              database_restore_username: 'registry_restore',
              database_restore_password: 'md5restorepassword',
              database: {
                dbname: 'registry'
              }
            }
          }
        )
      end

      it 'adds host md5 entries for backup user for each cidr address' do
        expect(chef_run).to render_file(template_path)
          .with_content(/^host\s+registry\s+registry_backup\s+10\.0\.0\.0\/8\s+md5$/)
        expect(chef_run).to render_file(template_path)
          .with_content(/^host\s+registry\s+registry_backup\s+192\.168\.1\.0\/24\s+md5$/)
      end

      it 'adds host md5 entries for restore user for each cidr address' do
        expect(chef_run).to render_file(template_path)
          .with_content(/^host\s+registry\s+registry_restore\s+10\.0\.0\.0\/8\s+md5$/)
        expect(chef_run).to render_file(template_path)
          .with_content(/^host\s+registry\s+registry_restore\s+192\.168\.1\.0\/24\s+md5$/)
      end
    end

    context 'with md5_auth_cidr_addresses and hostssl enabled' do
      before do
        stub_gitlab_rb(
          postgresql: {
            md5_auth_cidr_addresses: ['10.0.0.0/8'],
            hostssl: true,
            registry: {
              database_backup_username: 'registry_backup',
              database_backup_password: 'md5backuppassword',
              database_restore_username: 'registry_restore',
              database_restore_password: 'md5restorepassword',
              database: {
                dbname: 'registry'
              }
            }
          }
        )
      end

      it 'adds hostssl md5 entries for backup user' do
        expect(chef_run).to render_file(template_path)
          .with_content(/^hostssl\s+registry\s+registry_backup\s+10\.0\.0\.0\/8\s+md5$/)
      end

      it 'adds hostssl md5 entries for restore user' do
        expect(chef_run).to render_file(template_path)
          .with_content(/^hostssl\s+registry\s+registry_restore\s+10\.0\.0\.0\/8\s+md5$/)
      end
    end
  end

  context 'when a custom database name is configured' do
    before do
      stub_gitlab_rb(
        postgresql: {
          registry: {
            database_backup_username: 'registry_backup',
            database_backup_password: 'md5backuppassword',
            database_restore_username: 'registry_restore',
            database_restore_password: 'md5restorepassword',
            dbname: 'custom_registry_db'
          }
        }
      )
    end

    it 'uses the custom database name for backup user entry' do
      expect(chef_run).to render_file(template_path)
        .with_content(/^local\s+custom_registry_db\s+registry_backup\s+md5$/)
    end

    it 'uses the custom database name for restore user entry' do
      expect(chef_run).to render_file(template_path)
        .with_content(/^local\s+custom_registry_db\s+registry_restore\s+md5$/)
    end

    context 'with md5_auth_cidr_addresses configured' do
      before do
        stub_gitlab_rb(
          postgresql: {
            md5_auth_cidr_addresses: ['10.0.0.0/8'],
            registry: {
              database_backup_username: 'registry_backup',
              database_backup_password: 'md5backuppassword',
              database_restore_username: 'registry_restore',
              database_restore_password: 'md5restorepassword',
              dbname: 'custom_registry_db'
            }
          }
        )
      end

      it 'uses the custom database name for backup user host entry' do
        expect(chef_run).to render_file(template_path)
          .with_content(/^host\s+custom_registry_db\s+registry_backup\s+10\.0\.0\.0\/8\s+md5$/)
      end

      it 'uses the custom database name for restore user host entry' do
        expect(chef_run).to render_file(template_path)
          .with_content(/^host\s+custom_registry_db\s+registry_restore\s+10\.0\.0\.0\/8\s+md5$/)
      end
    end
  end

  context 'when only backup user is configured' do
    before do
      stub_gitlab_rb(
        postgresql: {
          registry: {
            database_backup_username: 'registry_backup',
            database_backup_password: 'md5backuppassword',
            dbname: 'registry'
          }
        }
      )
    end

    it 'adds only backup user authentication entry restricted to registry database' do
      expect(chef_run).to render_file(template_path)
        .with_content(/^local\s+registry\s+registry_backup\s+md5$/)
      expect(chef_run).not_to render_file(template_path)
        .with_content(/^local\s+registry\s+registry_restore\s+md5$/)
    end

    context 'with md5_auth_cidr_addresses configured' do
      before do
        stub_gitlab_rb(
          postgresql: {
            md5_auth_cidr_addresses: ['10.0.0.0/8'],
            registry: {
              database_backup_username: 'registry_backup',
              database_backup_password: 'md5backuppassword',
              database: {
                dbname: 'registry'
              }
            }
          }
        )
      end

      it 'adds host md5 entry only for backup user' do
        expect(chef_run).to render_file(template_path)
          .with_content(/^host\s+registry\s+registry_backup\s+10\.0\.0\.0\/8\s+md5$/)
        expect(chef_run).not_to render_file(template_path)
          .with_content(/^host\s+registry\s+registry_restore\s+10\.0\.0\.0\/8\s+md5$/)
      end
    end
  end

  context 'when only restore user is configured' do
    before do
      stub_gitlab_rb(
        postgresql: {
          registry: {
            database_restore_username: 'registry_restore',
            database_restore_password: 'md5restorepassword',
            dbname: 'registry'
          }
        }
      )
    end

    it 'adds only restore user authentication entry restricted to registry database' do
      expect(chef_run).to render_file(template_path)
        .with_content(/^local\s+registry\s+registry_restore\s+md5$/)
      expect(chef_run).not_to render_file(template_path)
        .with_content(/^local\s+registry\s+registry_backup\s+md5$/)
    end

    context 'with md5_auth_cidr_addresses configured' do
      before do
        stub_gitlab_rb(
          postgresql: {
            md5_auth_cidr_addresses: ['10.0.0.0/8'],
            registry: {
              database_restore_username: 'registry_restore',
              database_restore_password: 'md5restorepassword',
              database: {
                dbname: 'registry'
              }
            }
          }
        )
      end

      it 'adds host md5 entry only for restore user' do
        expect(chef_run).to render_file(template_path)
          .with_content(/^host\s+registry\s+registry_restore\s+10\.0\.0\.0\/8\s+md5$/)
        expect(chef_run).not_to render_file(template_path)
          .with_content(/^host\s+registry\s+registry_backup\s+10\.0\.0\.0\/8\s+md5$/)
      end
    end
  end

  context 'when backup user is configured but password is missing' do
    before do
      stub_gitlab_rb(
        postgresql: {
          registry: {
            database_backup_username: 'registry_backup',
            database_backup_password: nil,
            dbname: 'registry'
          }
        }
      )
    end

    it 'does not add backup user authentication entry' do
      expect(chef_run).not_to render_file(template_path)
        .with_content(/^local\s+registry\s+registry_backup\s+md5$/)
    end

    context 'with md5_auth_cidr_addresses configured' do
      before do
        stub_gitlab_rb(
          postgresql: {
            md5_auth_cidr_addresses: ['10.0.0.0/8'],
            registry: {
              database_backup_username: 'registry_backup',
              database_backup_password: nil,
              database: {
                dbname: 'registry'
              }
            }
          }
        )
      end

      it 'does not add host md5 entry for backup user' do
        expect(chef_run).not_to render_file(template_path)
          .with_content(/^host\s+registry\s+registry_backup\s+10\.0\.0\.0\/8\s+md5$/)
      end
    end
  end

  context 'when restore user is configured but password is missing' do
    before do
      stub_gitlab_rb(
        postgresql: {
          registry: {
            database_restore_username: 'registry_restore',
            database_restore_password: nil,
            dbname: 'registry'
          }
        }
      )
    end

    it 'does not add restore user authentication entry' do
      expect(chef_run).not_to render_file(template_path)
        .with_content(/^local\s+registry\s+registry_restore\s+md5$/)
    end

    context 'with md5_auth_cidr_addresses configured' do
      before do
        stub_gitlab_rb(
          postgresql: {
            md5_auth_cidr_addresses: ['10.0.0.0/8'],
            registry: {
              database_restore_username: 'registry_restore',
              database_restore_password: nil,
              database: {
                dbname: 'registry'
              }
            }
          }
        )
      end

      it 'does not add host md5 entry for restore user' do
        expect(chef_run).not_to render_file(template_path)
          .with_content(/^host\s+registry\s+registry_restore\s+10\.0\.0\.0\/8\s+md5$/)
      end
    end
  end

  context 'when no registry backup/restore users are configured' do
    it 'does not add any registry backup/restore user authentication entries' do
      expect(chef_run).not_to render_file(template_path)
        .with_content(/^local\s+registry\s+registry_backup\s+md5$/)
      expect(chef_run).not_to render_file(template_path)
        .with_content(/^local\s+registry\s+registry_restore\s+md5$/)
    end

    context 'with md5_auth_cidr_addresses configured' do
      before do
        stub_gitlab_rb(
          postgresql: {
            md5_auth_cidr_addresses: ['10.0.0.0/8']
          }
        )
      end

      it 'does not add any host md5 entries for registry backup/restore users' do
        expect(chef_run).not_to render_file(template_path)
          .with_content(/^host\s+registry\s+registry_backup\s+10\.0\.0\.0\/8\s+md5$/)
        expect(chef_run).not_to render_file(template_path)
          .with_content(/^host\s+registry\s+registry_restore\s+10\.0\.0\.0\/8\s+md5$/)
      end
    end
  end
end
