require 'chef_helper'

$LOAD_PATH << File.join(__dir__, '../../../files/gitlab-ctl-commands/lib')

require 'gitlab_ctl'

RSpec.describe GitlabCtl::Backup do
  let(:backup_dir_path) { '/etc/gitlab/config_backup' }

  # Valid backup files match the regular expression
  let(:future_valid_backup_files) do
    ['gitlab_config_2302886428_2042_12_22.tar']
  end

  let(:past_valid_backup_files) do
    [
      'gitlab_config_1603388428_2020_10_22.tar',
      'gitlab_config_1606070428_2020_11_22.tar',
      'gitlab_config_1608662428_2020_12_22.tar',
    ]
  end

  let(:valid_backup_files) do
    future_valid_backup_files + past_valid_backup_files
  end

  let(:invalid_backup_files) do
    [
      'lab_config_1600793789_2020_09_22.tar',
      'gitlab_config_manual.tar',
      'my_cool_backup.tar'
    ]
  end

  let(:all_backup_files) do
    valid_backup_files + invalid_backup_files
  end

  let(:warning_message) { "WARNING: In GitLab 14.0 we will begin removing all configuration backups older than" }

  before do
    allow(GitlabCtl::Backup).to receive(:print_warning?).and_return(false)
    allow(File).to receive(:exist?).and_return(true)
    allow(FileUtils).to receive(:chmod)
    allow(FileUtils).to receive(:chown)
    allow(FileUtils).to receive(:mkdir)
    allow_any_instance_of(Kernel).to receive(:system).and_return(true)
    allow_any_instance_of(Kernel).to receive(:exit!)
    allow(Dir).to receive(:chdir).and_yield
    allow(FileUtils).to receive(:rm)
    allow(Time).to receive(:now).and_return(Time.utc(2021))
    # Don't let messages output during test
    allow(STDOUT).to receive(:write)
  end

  context 'with default settings' do
    let(:options) { { delete_old_backups: nil } }

    before do
      allow(GitlabCtl::Util).to receive(:get_node_attributes).and_return({})
    end

    it 'should default to deleting old backups' do
      backup = GitlabCtl::Backup.new
      expect(backup.wants_pruned).to eq(true)
    end

    context 'when the backup path is readable by non-root' do
      before do
        allow_any_instance_of(GitlabCtl::Backup).to receive(:secure?).and_return(false)
      end

      it 'should warn the administrator' do
        expect { GitlabCtl::Backup.perform }.to output(/WARNING: #{backup_dir_path} may be read by non-root users/).to_stderr
      end
    end

    context 'when the backup path is readable by only root' do
      let(:archive_name) { 'gitlab_config_8675309_1981_11_16.tar' }

      before do
        allow_any_instance_of(GitlabCtl::Backup).to receive(:secure?).and_return(true)
        allow_any_instance_of(GitlabCtl::Backup).to receive(:archive_name).and_return(archive_name)
      end

      it 'should use proper tar command' do
        expect_any_instance_of(Kernel).to receive(:system).with(
          *%W(tar --absolute-names --dereference --verbose --create --file /etc/gitlab/config_backup/#{archive_name}
              --exclude /etc/gitlab/config_backup -- /etc/gitlab)
        )
        GitlabCtl::Backup.perform
      end

      it 'should set proper file mode on archive file' do
        expect(FileUtils).to receive(:chmod).with(0600, %r{#{backup_dir_path}/#{archive_name}})
        GitlabCtl::Backup.perform
      end

      it 'should notify about archive creation starting' do
        expect { GitlabCtl::Backup.perform }.to output(
          %r{Creating configuration backup archive: #{archive_name}}
        ).to_stdout
      end

      it 'should put notify about archive creation completion' do
        expect { GitlabCtl::Backup.perform }.to output(
          %r{Configuration backup archive complete: #{backup_dir_path}/#{archive_name}}
        ).to_stdout
      end

      it 'should be able to accept a backup directory path argument' do
        custom_dir = "/TanukisOfUnusualSize"
        options = { backup_path: custom_dir }
        expect { GitlabCtl::Backup.perform(options) }.to output(
          %r{Configuration backup archive complete: #{custom_dir}/#{archive_name}}
        ).to_stdout
      end

      context 'when etc backup path does not exist' do
        before do
          allow(File).to receive(:exist?).with(backup_dir_path).and_return(false)
        end

        it 'should log proper message' do
          expect { GitlabCtl::Backup.perform }.to output(
            %r{Could not find '#{backup_dir_path}' directory\. Creating\.}).to_stdout
        end

        it 'should create directory' do
          expect(FileUtils).to receive(:mkdir).with(backup_dir_path, mode: 0700)
          GitlabCtl::Backup.perform
        end

        it 'should set proper owner and group' do
          expect(FileUtils).to receive(:chown).with('root', 'root', backup_dir_path)
          GitlabCtl::Backup.perform
        end

        context 'when /etc/gitlab is NFS share' do
          before do
            allow(STDERR).to receive(:write)
            allow(FileUtils).to receive(:chown).with('root', 'root', backup_dir_path).and_raise(Errno::EPERM)
          end

          it 'should put proper output to STDERR' do
            expect { GitlabCtl::Backup.perform }.to output(
              /Warning: Could not change owner of #{backup_dir_path} to 'root:root'. As a result your backups may be accessible to some non-root users./).to_stderr
          end
        end
      end
    end

    context 'when etc path does not exist' do
      let(:etc_path) { '/etc/gitlab' }

      before do
        allow(File).to receive(:exist?).with(etc_path).and_return(false)
      end

      it "should abort with proper message" do
        expect { GitlabCtl::Backup.perform }.to output(/Could not find '#{etc_path}' directory. Is your package installed correctly?/).to_stderr.and raise_error
      end
    end
  end

  context 'when backup_keep_time is non-zero' do
    let(:options) { { delete_old_backups: true } }
    let(:node_config) do
      {
        'gitlab' => {
          'gitlab-rails' => {
            'backup_keep_time' => 1
          }
        }
      }
    end

    before do
      allow(GitlabCtl::Util).to receive(:get_node_attributes).and_return(node_config)
      allow(GitlabCtl::Backup).to receive(:secure?).and_return(true)
      @backup = GitlabCtl::Backup.new(options)
    end

    context 'when no valid files exist' do
      before do
        allow(Dir).to receive(:glob).and_return(invalid_backup_files)
        allow_any_instance_of(Kernel).to receive(:warn)
      end

      it 'should find no files to remove' do
        expect(@backup.removable_archives.length).to equal(0)
        expect(FileUtils).not_to have_received(:rm)
        expect { @backup.prune }.to output(/done. Removed 0 older configuration backups./).to_stdout
      end
    end

    context 'when files exist to remove' do
      before do
        allow(Dir).to receive(:glob).and_return(all_backup_files)
      end

      it 'should identify the correct files to remove' do
        removed = past_valid_backup_files.map do |x|
          File.join(backup_dir_path, x)
        end

        expect(@backup.removable_archives).to match_array(removed)
        @backup.remove_backups
        removed.each do |f|
          expect(FileUtils).to have_received(:rm).with(f)
        end
      end

      context 'when file removal fails' do
        let(:failed_file) { File.join(backup_dir_path, past_valid_backup_files[1]) }
        let(:message) { "Permission denied @ unlink_internal - #{failed_file}" }
        let(:removed_files) do
          files = past_valid_backup_files.map do |f|
            File.join(backup_dir_path, f)
          end

          files.select! { |f| f != failed_file }
        end

        before do
          allow(FileUtils).to receive(:rm).with(failed_file).and_raise(Errno::EACCES, message)
        end

        it 'removes the remaining expected files' do
          allow_any_instance_of(Kernel).to receive(:warn)
          @backup.remove_backups
          removed_files.each do |filename|
            expect(FileUtils).to have_received(:rm).with(filename)
          end
        end

        it 'sets the proper file removal count' do
          allow_any_instance_of(Kernel).to receive(:warn)
          expect { @backup.remove_backups }.to output(/done. Removed #{removed_files.length} older configuration backups./).to_stdout
        end

        it 'prints the error from file that could not be removed' do
          expect { @backup.remove_backups }.to output(a_string_matching(message)).to_stderr
        end
      end
    end

    context 'when the only valid files are after backup_keep_time' do
      before do
        allow(Dir).to receive(:glob).and_return(future_valid_backup_files)
      end

      it 'should find no files to remove' do
        allow_any_instance_of(Kernel).to receive(:warn)
        expect(@backup.removable_archives.length).to equal(0)
        expect(FileUtils).not_to have_received(:rm)
        expect { @backup.prune }.to output(/done. Removed 0 older configuration backups./).to_stdout
      end
    end
  end

  context 'when backup_keep_time is zero' do
    let(:options) { { delete_old_backups: nil } }
    let(:node_config) do
      {
        'gitlab' => {
          'gitlab-rails' => {
            'backup_keep_time' => 0
          }
        }
      }
    end

    before do
      allow(GitlabCtl::Util).to receive(:get_node_attributes).and_return(node_config)
      allow(GitlabCtl::Backup).to receive(:secure?).and_return(true)
      allow(Dir).to receive(:glob).and_return(all_backup_files)
      @backup = GitlabCtl::Backup.new(options)
    end

    it 'should skip performing a backup' do
      expect { @backup.prune }.to output(/Keeping all older configuration backups/).to_stdout
      expect(FileUtils).not_to have_received(:rm)
    end
  end

  context 'when node attributes invocation fails' do
    let(:options) { { delete_old_backups: nil } }

    before do
      allow(GitlabCtl::Util).to receive(:get_node_attributes).and_raise(GitlabCtl::Errors::NodeError, "Oh no, node failed")
      allow_any_instance_of(Kernel).to receive(:warn)
      allow(Dir).to receive(:glob).and_return(all_backup_files)
    end

    it 'should not remove old archives' do
      backup = GitlabCtl::Backup.new(options)
      expect { backup.prune }.to output(/Keeping all older configuration backups/).to_stdout
      expect(FileUtils).not_to have_received(:rm)
    end
  end

  context 'when node attributes returns an empty hash' do
    let(:options) { { delete_old_backups: nil } }

    before do
      allow(GitlabCtl::Util).to receive(:get_node_attributes).and_return({})
      allow_any_instance_of(Kernel).to receive(:warn)
      allow(Dir).to receive(:glob).and_return(all_backup_files)
    end

    it 'should not remove old archives' do
      backup = GitlabCtl::Backup.new(options)
      expect { backup.prune }.to output(/Keeping all older configuration backups/).to_stdout
      expect(FileUtils).not_to have_received(:rm)
    end
  end
end
