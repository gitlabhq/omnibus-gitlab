module GitlabCtl
  class Backup
    def self.perform(path = nil)
      backup_path = path.nil? ? '/etc/gitlab/config_backup' : path
      new.perform backup_path
    end

    def perform(dir_path)
      @etc_backup_path = File.expand_path(dir_path)
      @etc_path = '/etc/gitlab'

      abort "Could not find '#{etc_path}' directory. Is your package installed correctly?" unless File.exist?(etc_path)
      unless File.exist?(etc_backup_path)
        puts "Could not find '#{etc_backup_path}' directory. Creating."
        FileUtils.mkdir(etc_backup_path, mode: 0700)
        begin
          FileUtils.chown('root', 'root', etc_backup_path)
        rescue Errno::EPERM
          warn("Warning: Could not change owner of #{etc_backup_path} to 'root:root'. As a result your " \
               'backups may be accessible to some non-root users.')
        end
      end

      warn("WARNING: #{etc_backup_path} may be read by non-root users") unless secure?(etc_backup_path)

      puts "Running configuration backup\nCreating configuration backup archive: #{archive_name}"

      command = %W(tar --absolute-names --verbose --create --file #{archive_path}
                   --exclude #{etc_backup_path} -- #{etc_path})
      status = system(*command)

      FileUtils.chmod(0600, archive_path) if File.exist?(archive_path)

      exit!(1) unless status

      puts "Configuration backup archive complete: #{archive_path}"
    end

    def secure?(path)
      stat_data = File.stat(path)
      return false if stat_data.uid != 0
      return false unless stat_data.world_readable?.nil?

      true
    end

    attr_reader :etc_backup_path, :etc_path

    def archive_name
      @archive_name ||= "gitlab_config_#{Time.now.strftime('%s_%Y_%m_%d')}.tar"
    end

    def archive_path
      @archive_path = File.join(etc_backup_path, archive_name)
    end
  end
end
