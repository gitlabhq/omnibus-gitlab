module GitlabCtl
  class Backup
    attr_reader :etc_backup_path, :etc_path, :backup_keep_time, :remove_timestamp

    def initialize(options = {})
      backup_path = options[:backup_path].nil? ? '/etc/gitlab/config_backup' : options[:backup_path]
      @etc_backup_path = File.expand_path(backup_path)
      @etc_path = '/etc/gitlab'
      @backup_keep_time = node_attributes.dig('gitlab', 'gitlab-rails', 'backup_keep_time').to_i
      @remove_timestamp = Time.now - @backup_keep_time
      @delete_old_backups = options[:delete_old_backups]
      @removable_archives = []
    end

    # attribute methods
    def archive_path
      @archive_path = File.join(etc_backup_path, archive_name)
    end

    def archive_name
      @archive_name ||= "gitlab_config_#{Time.now.strftime('%s_%Y_%m_%d')}.tar"
    end

    def node_attributes
      @node_attributes ||= GitlabCtl::Util.get_node_attributes
    rescue GitlabCtl::Errors::NodeError => e
      warn(e.message)
      warn("Defaulting to keeping all backups")
      {}
    end

    def wants_pruned
      @delete_old_backups.nil? ? true : @delete_old_backups
    end

    def removable_archives
      return @removable_archives unless @removable_archives.empty?

      Dir.chdir(@etc_backup_path) do
        Dir.glob("gitlab_config_*.tar").map do |file_name|
          next unless file_name =~ %r{gitlab_config_(\d{10})_(\d{4}_\d{2}_\d{2}).tar}

          file_timestamp = Regexp.last_match(1).to_i

          next if @backup_keep_time.zero?

          next if Time.at(file_timestamp) >= @remove_timestamp

          file_path = File.expand_path(file_name, @etc_backup_path)

          @removable_archives.push(file_path)
        end
      end

      @removable_archives
    end

    # class methods
    def self.perform(options = {})
      backup = new(options)
      backup.perform
      backup.prune
    end

    def prune
      if wants_pruned && backup_keep_time.positive?
        remove_backups
      else
        puts "Keeping all older configuration backups"
      end
    end

    def perform(options = {})
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

      command = %W(tar --absolute-names --dereference --verbose --create --file #{archive_path}
                   --exclude #{etc_backup_path} -- #{etc_path})
      status = system(*command)

      FileUtils.chmod(0600, archive_path) if File.exist?(archive_path)

      exit!(1) unless status

      puts "Configuration backup archive complete: #{archive_path}"
    end

    def remove_backups
      # delete old backups
      removed_count = 0
      puts "Removing configuration backups older than #{@remove_timestamp} ..."

      removable_archives.each do |archive_file|
        FileUtils.rm(archive_file)
        puts "  Removed #{archive_file}"
        removed_count += 1
      rescue StandardError => e
        warn("WARNING: Deleting file #{archive_file} failed: #{e.message}")
      end
      puts "done. Removed #{removed_count} older configuration backups."
    end

    def secure?(path)
      stat_data = File.stat(path)
      return false if stat_data.uid != 0
      return false unless stat_data.world_readable?.nil?

      true
    end
  end
end
