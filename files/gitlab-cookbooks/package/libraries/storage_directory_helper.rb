#
# Copyright:: Copyright (c) 2016 GitLab Inc
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

require_relative 'helper'

class StorageDirectoryHelper
  include ShellOutHelper

  def initialize(owner, group, mode)
    @target_owner = owner
    @target_group = group
    @target_mode = mode
  end

  def writable?(path)
    do_shell_out("test -w #{path} -a -w $(readlink -f #{path})", @target_owner).exitstatus.zero?
  end

  def run_command(cmd, use_euid: false, throw_error: true)
    run_shell = Mixlib::ShellOut.new(cmd, user: (@target_owner if use_euid), group: (@target_group if use_euid))
    run_shell.run_command
    run_shell.error! if throw_error
    run_shell
  end

  def ensure_directory_exists(path)
    # Ensure the directory exists, create using the euid if the parent directory
    # is writable by the target_owner
    run_command("mkdir -p #{path}", use_euid: writable?(File.expand_path('..', path)))
  end

  def ensure_permissions_set(path)
    # If the owner doesn't match the expected owner, we need to chown.
    # Manual user intervention will be required if it fails. (enabling no_root_squash)
    run_chown(path) if @target_owner != get_owner(path)

    # Set the group on the directory, run using the euid if target_owner has
    # write access, otherwise use root
    run_command("chgrp #{@target_group} #{path}", use_euid: writable?(path)) if @target_group

    # Set the correct mode on the directory, run using the euid if target_owner
    # has write access, otherwise use root
    return unless @target_mode

    # Prepend a 0 to force an octal set when 4 bits have been passed in. eg: 2755 or 0700
    mode = @target_mode.length == 4 ? "0#{@target_mode}" : @target_mode
    run_command("chmod #{mode} #{path}", use_euid: writable?(path))
  end

  def get_owner(path)
    # Use stat to return the owner. The root user may not have execute permissions
    # to the directory, but the target_owner will in the success case, so always
    # use the euid to run the command
    run_command("stat --printf='%U' $(readlink -f #{path})", use_euid: true).stdout
  end

  def run_chown(path)
    # Chown will not work if it's in a root_squash directory, so the only workarounds
    # will be for the admin to manually chown on the nfs server, or use
    # 'no_root_squash' mode in their exports and re-run reconfigure
    path = File.realpath(path)
    FileUtils.chown(@target_owner, @target_group, path)
  rescue Errno::EPERM => e
    raise(
      e,
      "'root' cannot chown #{path}. If using NFS mounts you will need to "\
      "re-export them in 'no_root_squash' mode and try again.\n#{e}",
      e.backtrace
    )
  end

  def validate!(path)
    # Test that directory is in expected state and error if not.
    validate(path, throw_error: true)
  end

  def validate(path, throw_error: false)
    commands      = ["[ -d \"#{path}\" ]"]
    commands_info = ["Failed expecting \"#{path}\" to be a directory."]

    format_string = '%U'
    expect_string = ''
    expect_string << @target_owner.to_s

    if @target_group
      format_string << ':%G'
      expect_string << ":#{@target_group}"
    end

    commands      << "[ \"$(stat --printf='#{format_string}' $(readlink -f #{path}))\" = '#{expect_string}' ]"
    commands_info << "Failed asserting that ownership of \"#{path}\" was #{expect_string}"

    if @target_mode
      commands      << "[ \"$(stat --printf='%04a' $(readlink -f #{path}) | grep -o '#{'.' * @target_mode.length}$')\" = '#{@target_mode}' ]"
      commands_info << "Failed asserting that mode permissions on \"#{path}\" is #{@target_mode}"
    end

    result = true
    commands.each_index do |index|
      result &&= validate_command(commands[index], throw_error: throw_error, error_message: commands_info[index])
      break unless result
    end

    result
  end

  def validate_command(cmd, throw_error: false, error_message: nil)
    # Test that directory is in expected state. The root user may not have
    # execute permissions to the directory, but the target_owner will in the
    # success case, so always use the euid to run the command, and use a custom error message
    cmd = run_command("set -x && #{cmd}", use_euid: true, throw_error: false)
    cmd.invalid!(error_message) if cmd.exitstatus != 0 && throw_error
    cmd.exitstatus.zero?
  end
end
