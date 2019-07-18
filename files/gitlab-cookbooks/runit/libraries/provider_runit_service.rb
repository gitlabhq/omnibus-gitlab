#
# Cookbook:: runit
# Provider:: service
#
# Author:: Joshua Timberman <jtimberman@chef.io>
# Author:: Sean OMeara <sean@sean.io>
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

class Chef
  class Provider
    class RunitService < Chef::Provider::LWRPBase
      unless defined?(VALID_SIGNALS)
        # Mapping of valid signals with optional friendly name
        VALID_SIGNALS = Mash.new(
          :down => nil,
          :hup => nil,
          :int => nil,
          :term => nil,
          :kill => nil,
          :quit => nil,
          :up => nil,
          :once => nil,
          :cont => nil,
          1 => :usr1,
          2 => :usr2
        )
      end

      use_inline_resources # ~FC113

      def whyrun_supported?
        true
      end

      # Mix in helpers from libraries/helpers.rb
      include RunitCookbook::Helpers

      # actions
      action :create do
        omnibus_helper = get_omnibus_helper

        ruby_block 'restart_service' do
          block do
            previously_enabled = enabled?
            action_enable

            # Only restart the service if it was previously enabled. If the service was disabled
            # or not running, then the enable action will start the service, and it's unnecessary
            # to restart the service again.
            restart_service if previously_enabled
          end
          action :nothing
          only_if { new_resource.restart_on_update && omnibus_helper.should_notify?(new_resource.name) }
        end

        ruby_block 'restart_log_service' do
          block do
            action_enable
            restart_log_service
          end
          action :nothing
        end

        ruby_block 'reload_log_service' do
          block do
            action_enable
            reload_log_service
          end
          action :nothing
        end

        # sv_templates
        if new_resource.sv_templates

          directory sv_dir_name do
            owner new_resource.owner unless new_resource.owner.nil?
            group new_resource.group unless new_resource.group.nil?
            mode '0755'
            recursive true
            action :create
          end

          template "#{sv_dir_name}/run" do
            owner new_resource.owner unless new_resource.owner.nil?
            group new_resource.group unless new_resource.group.nil?
            source "sv-#{new_resource.run_template_name}-run.erb"
            cookbook template_cookbook
            mode '0755'
            variables(options: new_resource.options)
            action :create
            notifies :run, 'ruby_block[restart_service]', :delayed
          end

          # log stuff
          if new_resource.log
            directory "#{sv_dir_name}/log" do
              owner new_resource.owner unless new_resource.owner.nil?
              group new_resource.group unless new_resource.group.nil?
              mode '0755'
              recursive true
              action :create
            end

            directory "#{sv_dir_name}/log/main" do
              owner new_resource.owner unless new_resource.owner.nil?
              group new_resource.group unless new_resource.group.nil?
              mode '0755'
              recursive true
              action :create
            end

            template "#{sv_dir_name}/log/run" do
              owner new_resource.owner unless new_resource.owner.nil?
              group new_resource.group unless new_resource.group.nil?
              mode '0755'
              source "sv-#{new_resource.log_template_name}-log-run.erb"
              cookbook template_cookbook
              variables(options: new_resource.options)
              action :create
              notifies :create, 'ruby_block[restart_log_service]'
            end

            template "#{new_resource.options[:log_directory]}/config" do
              owner new_resource.owner unless new_resource.owner.nil?
              group new_resource.group unless new_resource.group.nil?
              mode '0644'
              action :create
              cookbook template_cookbook
              source "sv-#{new_resource.log_template_name}-log-config.erb"
              variables new_resource.log_options
              notifies :create, 'ruby_block[reload_log_service]'
              notifies :create, "ruby_block[verify_chown_persisted_on_#{new_resource.name}]", :immediately
            end

            ruby_block "verify_chown_persisted_on_#{new_resource.name}" do
              block do
                omnibus_helper = get_omnibus_helper
                config_path = "#{new_resource.options[:log_directory]}/config"
                # Check one at a time in case either is ever not specified
                user_matches = new_resource.owner.nil? ? true : omnibus_helper.expected_user?(config_path, new_resource.owner)
                group_matches = new_resource.group.nil? ? true : omnibus_helper.expected_group?(config_path, new_resource.group)
                raise "Unable to persist filesystem ownership changes of #{config_path}. See https://docs.gitlab.com/ee/administration/high_availability/nfs.html#recommended-options for guidance." unless (user_matches && group_matches)
              end
              action :nothing
            end

          end

          # environment stuff
          directory "#{sv_dir_name}/env" do
            owner new_resource.owner unless new_resource.owner.nil?
            group new_resource.group unless new_resource.group.nil?
            mode '0755'
            action :create
          end

          new_resource.env.map do |var, value|
            file "#{sv_dir_name}/env/#{var}" do
              owner new_resource.owner unless new_resource.owner.nil?
              group new_resource.group unless new_resource.group.nil?
              content value
              sensitive true if Chef::Resource.instance_methods(false).include?(:sensitive)
              mode '0640'
              action :create
            end
          end

          ruby_block "Delete unmanaged env files for #{new_resource.name} service" do
            block { delete_extra_env_files }
            only_if { extra_env_files? }
            not_if { new_resource.env.empty? }
            action :run
          end

          template "#{sv_dir_name}/check" do
            owner new_resource.owner unless new_resource.owner.nil?
            group new_resource.group unless new_resource.group.nil?
            mode '0755'
            cookbook template_cookbook
            source "sv-#{new_resource.check_script_template_name}-check.erb"
            variables(options: new_resource.options)
            action :create
            only_if { new_resource.check }
          end

          template "#{sv_dir_name}/finish" do
            owner new_resource.owner unless new_resource.owner.nil?
            group new_resource.group unless new_resource.group.nil?
            mode '0755'
            source "sv-#{new_resource.finish_script_template_name}-finish.erb"
            cookbook template_cookbook
            variables(options: new_resource.options) if new_resource.options.respond_to?(:has_key?)
            action :create
            only_if { new_resource.finish }
          end

          directory "#{sv_dir_name}/control" do
            owner new_resource.owner unless new_resource.owner.nil?
            group new_resource.group unless new_resource.group.nil?
            mode '0755'
            action :create
          end

          new_resource.control.map do |signal|
            template "#{sv_dir_name}/control/#{signal}" do
              owner new_resource.owner unless new_resource.owner.nil?
              group new_resource.group unless new_resource.group.nil?
              mode '0755'
              source "sv-#{new_resource.control_template_names[signal]}-control-#{signal}.erb"
              cookbook template_cookbook
              variables(options: new_resource.options)
              action :create
            end
          end

          link "#{parsed_lsb_init_dir}/#{new_resource.service_name}" do
            to sv_bin
            action :create
          end

          # Create/Delete service down file
          # To prevent unexpected behavior, require users to explicitly set
          # delete_downfile to remove any down file that may already exist
          df_action = :nothing
          df_action = if new_resource.down
                        :create
                      else
                        :delete
                      end

          file down_file do
            mode '0644'
            backup false
            content '# File created and managed by chef!'
            action df_action
          end
        end
      end

      action :enable do
        # FIXME: remove action_create in next major version
        action_create

        omnibus_helper = get_omnibus_helper

        directory new_resource.service_dir

        link service_dir_name.to_s do
          to sv_dir_name
          action :create
        end

        ruby_block "wait for #{new_resource.service_name} service socket" do
          block do
            wait_for_service
          end
          action :run
          not_if { FileTest.pipe?("#{sv_dir_name}/supervise/ok") }
        end

        # Support supervisor owner and groups http://smarden.org/runit/faq.html#user
        if new_resource.supervisor_owner || new_resource.supervisor_group
          directory "#{service_dir_name}/supervise" do
            mode '0755'
            action :create
          end

          directory "#{service_dir_name}/log/supervise" do
            mode '0755'
            action :create
          end

          %w(ok status control).each do |target|
            supervisor_owner = new_resource.supervisor_owner || 'root'
            supervisor_group = new_resource.supervisor_group || 'root'

            file "#{sv_dir_name}/supervise/#{target}" do
              owner supervisor_owner
              group supervisor_group
              action :touch
              only_if { !omnibus_helper.expected_owner?(name, supervisor_owner, supervisor_group) }
            end

            file "#{sv_dir_name}/log/supervise/#{target}" do
              owner supervisor_owner
              group supervisor_group
              action :touch
              only_if { !omnibus_helper.expected_owner?(name, supervisor_owner, supervisor_group) }
            end
          end
        end
      end

      # signals
      VALID_SIGNALS.each do |signal, signal_name|
        action(signal_name || signal) do
          if running?
            Chef::Log.info "#{new_resource} signalled (#{(signal_name || signal).to_s.upcase})"
            runit_send_signal(signal, signal_name)
          else
            Chef::Log.debug "#{new_resource} not running - nothing to do"
          end
        end
      end

      action :nothing do
      end

      action :restart do
        restart_service
      end

      action :start do
        if running?
          Chef::Log.debug "#{new_resource} already running - nothing to do"
        else
          start_service
          Chef::Log.info "#{new_resource} started"
        end
      end

      action :stop do
        if running?
          stop_service
          Chef::Log.info "#{new_resource} stopped"
        else
          Chef::Log.debug "#{new_resource} already stopped - nothing to do"
        end
      end

      action :reload do
        if running?
          reload_service
          Chef::Log.info "#{new_resource} reloaded"
        else
          Chef::Log.debug "#{new_resource} not running - nothing to do"
        end
      end

      action :status do
        running?
      end

      action :disable do
        ruby_block "disable #{new_resource.service_name}" do
          block { disable_service }
          only_if { enabled? }
        end
      end
    end
  end
end
