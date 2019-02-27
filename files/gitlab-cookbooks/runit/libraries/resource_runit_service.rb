#
# Cookbook:: runit
# Provider:: service
#
# Copyright:: 2011-2016, Joshua Timberman
# Copyright:: 2011-2016, Chef Software, Inc.
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

require 'chef/resource'
require 'chef/resource/service'

class Chef
  class Resource
    # Missing top-level class documentation comment
    class RunitService < Chef::Resource::Service
      def initialize(name, run_context = nil)
        super
        runit_node = runit_attributes_from_node(run_context)
        @resource_name = :runit_service
        @provider = Chef::Provider::RunitService
        @supports = { restart: true, reload: true, status: true }
        @action = :enable
        @allowed_actions = [:nothing, :start, :stop, :enable, :disable, :restart, :reload, :status, :once, :hup, :cont, :term, :kill, :up, :down, :usr1, :usr2, :create]

        # sv_bin, sv_dir, service_dir and lsb_init_dir may have been set in the
        # node attributes
        @sv_bin = runit_node[:sv_bin] || '/usr/bin/sv'
        @sv_dir = runit_node[:sv_dir] || '/etc/sv'
        @service_dir = runit_node[:service_dir] || '/etc/service'
        @lsb_init_dir = runit_node[:lsb_init_dir] || '/etc/init.d'

        @control = []
        @options = {}
        @env = {}
        @log = true
        @cookbook = nil
        @check = false
        @finish = false
        @down = false
        @supervisor_owner = nil
        @supervisor_group = nil
        @owner = "root"
        @group = "root"
        @enabled = false
        @running = false
        @default_logger = false
        @restart_on_update = true
        @run_template_name = @service_name
        @log_template_name = @service_name
        @check_script_template_name = @service_name
        @finish_script_template_name = @service_name
        @control_template_names = {}
        @sv_templates = true
        @sv_timeout = nil
        @sv_verbose = false
        @log_options = {}
        @start_command = "start"
        @stop_command = "stop"
        @restart_command = "restart"
        @status_command = "status"
      end

      def after_created
        #
        # Backward Compat Hack
        #
        # This ensures a 'service' resource exists for all 'runit_service' resources.
        # This should allow all recipes using the previous 'runit_service' definition to
        # continue operating.
        #
        unless run_context.nil?
          service_dir_name = ::File.join(@service_dir, @name)
          control_cmd = @sv_bin
          control_cmd = "#{node[:runit][:chpst_bin]} -u #{@owner}:#{@group} #{control_cmd}" if @owner
          @service_mirror = Chef::Resource::Service.new(name, run_context)
          @service_mirror.provider(Chef::Provider::Service::Simple)
          @service_mirror.supports(@supports)
          @service_mirror.start_command("#{control_cmd} #{@start_command} #{service_dir_name}")
          @service_mirror.stop_command("#{control_cmd} #{@stop_command} #{service_dir_name}")
          @service_mirror.restart_command("#{control_cmd} #{@restart_command} #{service_dir_name}")
          @service_mirror.status_command("#{control_cmd} #{@status_command} #{service_dir_name}")
          @service_mirror.action(:nothing)
          run_context.resource_collection.insert(@service_mirror)
        end
      end

      def sv_bin(arg = nil)
        set_or_return(:sv_bin, arg, kind_of: [String])
      end

      def sv_dir(arg = nil)
        set_or_return(:sv_dir, arg, kind_of: [String, FalseClass])
      end

      def sv_timeout(arg = nil)
        set_or_return(:sv_timeout, arg, kind_of: [Integer])
      end

      def sv_verbose(arg = nil)
        set_or_return(:sv_verbose, arg, kind_of: [TrueClass, FalseClass])
      end

      def service_dir(arg = nil)
        set_or_return(:service_dir, arg, kind_of: [String])
      end

      def lsb_init_dir(arg = nil)
        set_or_return(:lsb_init_dir, arg, kind_of: [String])
      end

      def control(arg = nil)
        set_or_return(:control, arg, kind_of: [Array])
      end

      def options(arg = nil)
        default_opts = @env.empty? ? @options : @options.merge(env_dir: ::File.join(@sv_dir, @service_name, 'env'))

        merged_opts = arg.respond_to?(:merge) ? default_opts.merge(arg) : default_opts

        set_or_return(
          :options,
          merged_opts,
          kind_of: [Hash],
          default: default_opts
        )
      end

      def env(arg = nil)
        set_or_return(:env, arg, kind_of: [Hash])
      end

      ## set log to current instance value if nothing is passed.
      def log(arg = @log)
        set_or_return(:log, arg, kind_of: [TrueClass, FalseClass])
      end

      def cookbook(arg = nil)
        set_or_return(:cookbook, arg, kind_of: [String])
      end

      def finish(arg = nil)
        set_or_return(:finish, arg, kind_of: [TrueClass, FalseClass])
      end

      def check(arg = nil)
        set_or_return(:check, arg, kind_of: [TrueClass, FalseClass])
      end

      def down(arg = nil)
        set_or_return(:start_down, arg, kind_of: [TrueClass, FalseClass])
      end

      def delete_downfile(arg = nil)
        set_or_return(:delete_downfile, arg, kind_of: [TrueClass, FalseClass])
      end

      def supervisor_owner(arg = nil)
        set_or_return(:supervisor_owner, arg, regex: [Chef::Config[:user_valid_regex]])
      end

      def supervisor_group(arg = nil)
        set_or_return(:supervisor_group, arg, regex: [Chef::Config[:group_valid_regex]])
      end

      def owner(arg = nil)
        set_or_return(:owner, arg, regex: [Chef::Config[:user_valid_regex]])
      end

      def group(arg = nil)
        set_or_return(:group, arg, regex: [Chef::Config[:group_valid_regex]])
      end

      def default_logger(arg = nil)
        set_or_return(:default_logger, arg, kind_of: [TrueClass, FalseClass])
      end

      def restart_on_update(arg = nil)
        set_or_return(:restart_on_update, arg, kind_of: [TrueClass, FalseClass])
      end

      def run_template_name(arg = nil)
        set_or_return(:run_template_name, arg, kind_of: [String])
      end
      alias template_name run_template_name

      def log_template_name(arg = nil)
        set_or_return(:log_template_name, arg, kind_of: [String])
      end

      def check_script_template_name(arg = nil)
        set_or_return(:check_script_template_name, arg, kind_of: [String])
      end

      def finish_script_template_name(arg = nil)
        set_or_return(:finish_script_template_name, arg, kind_of: [String])
      end

      def control_template_names(arg = nil)
        set_or_return(
          :control_template_names,
          arg,
          kind_of: [Hash],
          default: set_control_template_names
        )
      end

      def set_control_template_names
        @control.each do |signal|
          @control_template_names[signal] ||= @service_name
        end
        @control_template_names
      end

      def sv_templates(arg = nil)
        set_or_return(:sv_templates, arg, kind_of: [TrueClass, FalseClass])
      end

      def log_options(arg = nil)
        set_or_return(:log_options, arg, kind_of: [Hash])
      end

      def start_command(arg = nil)
        set_or_return(:start_command, arg, kind_of: [String])
      end

      def stop_command(arg = nil)
        set_or_return(:stop_command, arg, kind_of: [String])
      end

      def restart_command(arg = nil)
        set_or_return(:restart_command, arg, kind_of: [String])
      end

      def status_command(arg = nil)
        set_or_return(:status_command, arg, kind_of: [String])
      end

      def runit_attributes_from_node(run_context)
        if run_context && run_context.node && run_context.node['runit']
          run_context.node['runit']
        else
          {}
        end
      end
    end
  end
end
