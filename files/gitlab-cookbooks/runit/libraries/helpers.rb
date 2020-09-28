#
# Cookbook:: runit
# Library:: helpers
#
# Author:: Joshua Timberman <joshua@chef.io>
# Author:: Sean OMeara <sean@sean.io>
# Copyright:: 2008-2019, Chef Software, Inc. <legal@chef.io>
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

module RunitCookbook
  module Helpers
    # include Chef::Mixin::ShellOut if it is not already included in the calling class
    def self.included(klass)
      klass.class_eval { include Chef::Mixin::ShellOut } unless klass.ancestors.include?(Chef::Mixin::ShellOut)
    end

    def down_file
      ::File.join(sv_dir_name, 'down')
    end

    def env_dir
      ::File.join(sv_dir_name, 'env')
    end

    def extra_env_files?
      files = []
      Dir.glob(::File.join(sv_dir_name, 'env', '*')).each do |f|
        files << File.basename(f)
      end
      return true if files.sort != new_resource.env.keys.sort
      false
    end

    def delete_extra_env_files
      Dir.glob(::File.join(sv_dir_name, 'env', '*')).each do |f|
        unless new_resource.env.key?(File.basename(f))
          File.unlink(f)
          Chef::Log.info("removing file #{f}")
        end
      end
    end

    def wait_for_service
      raise 'Runit does not appear to be installed. Include runit::default before using the resource!' unless binary_exists?

      sleep 1 until ::FileTest.pipe?(::File.join(service_dir_name, 'supervise', 'ok'))

      if new_resource.log
        sleep 1 until ::FileTest.pipe?(::File.join(service_dir_name, 'log', 'supervise', 'ok'))
      end
    end

    def runit_send_signal(signal, friendly_name = nil)
      friendly_name ||= signal
      converge_by("send #{friendly_name} to #{new_resource}") do
        safe_sv_shellout!("#{sv_args}#{signal} #{service_dir_name}")
        Chef::Log.info("#{new_resource} sent #{friendly_name}")
      end
    end

    def running?
      cmd = safe_sv_shellout("#{sv_args}#{new_resource.status_command_name} #{service_dir_name}", returns: [0, 100])
      !cmd.error? && cmd.stdout =~ /^run:/
    end

    def log_running?
      cmd = safe_sv_shellout("#{sv_args}status #{::File.join(service_dir_name, 'log')}", returns: [0, 100])
      !cmd.error? && cmd.stdout =~ /^run:/
    end

    def enabled?
      ::File.exist?(::File.join(service_dir_name, 'run'))
    end

    def log_service_name
      ::File.join(new_resource.service_name, 'log')
    end

    def sv_dir_name
      ::File.join(new_resource.sv_dir, new_resource.service_name)
    end

    def sv_args
      sv_args = ''
      sv_args += "-w #{new_resource.sv_timeout} " unless new_resource.sv_timeout.nil?
      sv_args += '-v ' if new_resource.sv_verbose
      sv_args
    end

    def service_dir_name
      ::File.join(new_resource.service_dir, new_resource.service_name)
    end

    def log_dir_name
      ::File.join(new_resource.service_dir, new_resource.service_name, log)
    end

    def binary_exists?
      begin
        Chef::Log.debug("Checking to see if the runit binary exists by running #{new_resource.sv_bin}")
        shell_out!(new_resource.sv_bin.to_s, returns: [0, 100])
      rescue Errno::ENOENT
        Chef::Log.debug("Failed to return 0 or 100 running #{new_resource.sv_bin}")
        return false
      end
      true
    end

    def safe_sv_shellout(command, options = {})
      begin
        Chef::Log.debug("Attempting to run runit command: #{new_resource.sv_bin} #{command}")
        cmd = shell_out("#{new_resource.sv_bin} #{command}", options)
      rescue Errno::ENOENT
        if binary_exists?
          raise # Some other cause
        else
          raise 'Runit does not appear to be installed. You must install runit before using the runit_service resource!'
        end
      end
      cmd
    end

    def safe_sv_shellout!(command, options = {})
      safe_sv_shellout(command, options).tap(&:error!)
    end

    def disable_service
      Chef::Log.debug("Attempting to disable runit service with: #{new_resource.sv_bin} #{sv_args}down #{service_dir_name}")
      shell_out("#{new_resource.sv_bin} #{sv_args}down #{service_dir_name}")
      FileUtils.rm(service_dir_name)

      # per the documentation, a service should be removed from supervision
      # within 5 seconds of removing the service dir symlink, so we'll sleep for 6.
      # otherwise, runit recreates the 'ok' named pipe too quickly
      Chef::Log.debug('Sleeping 6 seconds to allow the disable to take effect')
      sleep(6)
      # runit will recreate the supervise directory and
      # pipes when the service is reenabled
      Chef::Log.debug("Removing #{::File.join(sv_dir_name, 'supervise', 'ok')}")
      FileUtils.rm(::File.join(sv_dir_name, 'supervise', 'ok'))
    end

    def start_service
      safe_sv_shellout!("#{sv_args}#{new_resource.start_command_name} #{service_dir_name}")
    end

    def stop_service
      safe_sv_shellout!("#{sv_args}#{new_resource.stop_command_name} #{service_dir_name}")
    end

    def restart_service
      safe_sv_shellout!("#{sv_args}#{new_resource.restart_command_name} #{service_dir_name}")
    end

    def restart_log_service
      safe_sv_shellout!("#{sv_args}restart #{::File.join(service_dir_name, 'log')}")
    end

    def reload_service
      safe_sv_shellout!("#{sv_args}force-reload #{service_dir_name}")
    end

    def reload_log_service
      if log_running?
        safe_sv_shellout!("#{sv_args}force-reload #{::File.join(service_dir_name, 'log')}")
      else
        Chef::Log.debug('Logging not running so doing nothing')
      end
    end

    def get_omnibus_helper
      OmnibusHelper.new(run_context.node)
    end
  end
end
