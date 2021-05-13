#
# Copyright:: Copyright (c) 2017 GitLab Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl/backup"

add_command_under_category('backup-etc', 'backup',
                           'Backup GitLab configuration [options]', 2) do |cmd_name, *args|
  def get_ctl_options
    options = {}
    leftover_args = OptionParser.new do |opts|
      opts.banner = "Usage: gitlab-ctl backup-etc [options]"

      opts.on('--[no-]delete-old-backups', 'Delete backups older than the specified "backup_keep_time" setting') do |delete_old_backups|
        options[:delete_old_backups] = delete_old_backups
      end

      opts.on('-p', '--backup-path BACKUP_PATH', 'Archive backups to BACKUP_PATH') do |p|
        options[:backup_path] = p
      end

      opts.on("-h", "--help", "Prints this help") do
        puts opts
        exit
      end
    end.parse!(ARGV.dup)

    # backwards compatibility with the bare [accepts directory path]
    # leftover_args will be ['gitlab','omnibus-ctl','backup-etc',[possible backup path],[extra bare options...]]
    if options[:backup_path].nil? && leftover_args.size >= 4
      log 'Specifying a custom backup path as a bare option is deprecated.'\
          ' Please use the -p or --backup-path option to specify a custom backup path.'
      options[:backup_path] = leftover_args[3]
    end

    options
  end

  GitlabCtl::Backup.perform(get_ctl_options)
end
