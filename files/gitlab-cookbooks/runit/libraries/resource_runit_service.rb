#
# Cookbook:: runit
# resource:: runit_service
#
# Author:: Joshua Timberman <jtimberman@chef.io>
# Copyright:: 2011-2019, Chef Software Inc.
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
      resource_name :runit_service

      default_action :enable

      # For legacy reasons we allow setting these via attribute
      property :sv_bin, String, default: lazy { node['runit']['sv_bin'] || (platform_family?('debian') ? '/usr/bin/sv' : '/sbin/sv') }
      property :sv_dir, [String, FalseClass], default: lazy { node['runit']['sv_dir'] || '/etc/sv' }
      property :service_dir, String, default: lazy { node['runit']['service_dir'] || '/etc/service' }
      property :lsb_init_dir, String, default: lazy { node['runit']['lsb_init_dir'] || '/etc/init.d' }

      property :control, Array, default: []
      property :options, Hash, default: lazy { default_options }, coerce: proc { |r| default_options.merge(r) if r.respond_to?(:merge) }
      property :env, Hash, default: {}
      property :log, [true, false], default: true
      property :cookbook, String
      property :check, [true, false], default: false
      property :start_down, [true, false], default: false
      property :delete_downfile, [true, false], default: false
      property :finish, [true, false], default: false
      property :supervisor_owner, String, regex: [Chef::Config[:user_valid_regex]]
      property :supervisor_group, String, regex: [Chef::Config[:group_valid_regex]]
      property :owner, String, regex: [Chef::Config[:user_valid_regex]], default: 'root'
      property :group, String, regex: [Chef::Config[:group_valid_regex]], default: 'root'
      property :enabled, [true, false], default: false
      property :running, [true, false], default: false
      property :default_logger, [true, false], default: false
      property :restart_on_update, [true, false], default: true
      property :run_template_name, String, default: lazy { service_name }
      property :log_template_name, String, default: lazy { service_name }
      property :check_script_template_name, String, default: lazy { service_name }
      property :finish_script_template_name, String, default: lazy { service_name }
      property :control_template_names, Hash, default: lazy { set_control_template_names }
      property :start_command_name, String, default: 'start'
      property :stop_command_name, String, default: 'stop'
      property :restart_command_name, String, default: 'restart'
      property :status_command_name, String, default: 'status'
      property :sv_templates, [true, false], default: true
      property :sv_timeout, Integer
      property :sv_verbose, [true, false], default: false
      property :log_options, Hash

      # Use a link to sv instead of a full blown init script calling runit.
      # This was added for omnibus projects and probably shouldn't be used elsewhere
      property :use_init_script_sv_link, [true, false], default: true

      alias template_name run_template_name

      def set_control_template_names
        template_names = {}
        control.each do |signal|
          template_names[signal] ||= service_name
        end
        template_names
      end

      # the default legacy options kept for compatibility with the definition
      #
      # @return [Hash] if env is the default empty hash then return env_dir value. Otherwise return an empty hash
      def default_options
        env.empty? ? { env_dir: ::File.join(sv_dir, service_name, 'env') } : {}
      end

      def after_created
        unless run_context.nil?
          new_resource = self
          service_dir_name = ::File.join(service_dir, service_name)
          control_cmd = new_resource.sv_bin
          control_cmd = "#{node[:runit][:chpst_bin]} -u #{new_resource.owner}:#{new_resource.group} #{control_cmd}" if new_resource.owner

          find_resource(:service, new_resource.name) do # creates if it does not exist
            provider Chef::Provider::Service::Simple
            supports new_resource.supports
            start_command "#{control_cmd} #{new_resource.start_command_name} #{service_dir_name}"
            stop_command "#{control_cmd} #{new_resource.stop_command_name} #{service_dir_name}"
            restart_command "#{control_cmd} #{new_resource.restart_command_name} #{service_dir_name}"
            status_command "#{control_cmd} #{new_resource.status_command_name} #{service_dir_name}"
            action :nothing
          end
        end
      end
    end
  end
end
