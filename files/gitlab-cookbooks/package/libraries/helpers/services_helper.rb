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

module Services # rubocop:disable Style/MultilineIfModifier (disabled so we can use `unless defined?(Services)` at the end of the class definition)
  ALL_SERVICES = 'all'.freeze
  ALL_GROUPS = 'all-groups'.freeze
  SYSTEM_GROUP = 'system'.freeze
  DEFAULT_GROUP = 'default'.freeze

  class Config
    def self.list
      @services.dup
    end

    def self.service(name, **config)
      @services ||= {}

      # A service config object always needs a group array
      @services[name] = { groups: [] }.merge(config)
    end
  end

  class << self
    # Disables the group of services that were passed as arguments
    #
    # Excludes the group, or array of groups, provided in the `except` argument
    # ex: Services.disable_group('redis')
    #     Services.disable_group('monitoring', except: ['redis', 'postgres'])
    #     Services.disable_group(Services::ALL_GROUPS, except: 'redis')
    def disable_group(*groups, except: nil, include_system: false)
      exceptions = [except].flatten
      exceptions << SYSTEM_GROUP unless include_system
      set_service_groups_status(false, *groups, except: exceptions)
    end

    # Enables the group of services that were passed as arguments
    #
    # Excludes the group, or array of groups, provided in the `except` argument
    # ex: Services.enable_group('redis')
    #     Services.enable_group('monitoring', except: ['redis', 'postgres'])
    #     Services.enable_group(Services::DEFAULT_GROUP, except: 'redis')
    def enable_group(*groups, except: nil)
      set_service_groups_status(true, *groups, except: except)
    end

    # Disables the services that were passed as arguments
    #
    # Excludes the service, or array of services, provided in the `except` argument
    # ex: Services.disable('mailroom')
    #     Services.disable(Services::ALL_SERVICES, except: ['redis', 'sentinel'])
    def disable(*services, except: nil, include_system: false)
      # Automatically excludes system services unless `include_system: true` is passed
      exceptions = [except].flatten
      exceptions.concat(system_services.keys) unless include_system

      set_services_status(false, *services, except: exceptions)
    end

    # Enables the services that were passed as arguments
    #
    # Excludes the service, or array of services, provided in the `except` argument
    # ex: Services.enable('mailroom')
    #     Services.enable(Services::ALL_SERVICES, except: ['monitoring'])
    def enable(*services, except: nil)
      set_services_status(true, *services, except: except)
    end

    # Sets the enable status from the first argument on the services that were passed as arguments
    #
    # Excludes the service, or array of services, provided in the `except` argument
    def set_enable(*services, value, except: nil, include_system: false)
      if value
        enable(*services, except: except)
      else
        disable(*services, except: except, include_system: include_system)
      end
    end

    # Sets the enable status from the first argument on the service groups that were passed as arguments
    #
    # Excludes the service group, or array of service groups, provided in the `except` argument
    def set_enable_group(*groups, value, except: nil, include_system: false)
      if value
        enable_group(*groups, except: except)
      else
        disable_group(*groups, except: except, include_system: include_system)
      end
    end

    def system_services
      find_by_group(SYSTEM_GROUP)
    end

    def find_by_group(group)
      service_list.select { |name, service| service[:groups].include?(group) }
    end

    def service_list
      # Merge together and cache all the service lists (from the different cookbooks)
      @service_list ||= [{}, *cookbook_services.dup.values].inject(&:merge)
    end

    def add_services(cookbook, services)
      # Add services from cookbooks
      cookbook_services[cookbook] = services
    end

    def reset_list
      @cookbook_services = nil
      @service_list = nil
    end

    def enabled?(service)
      user_config = Gitlab[service]['enable']

      # If service is enabled in user-config the user-config value is Used (in case we haven't consumed them into the node yet)
      # And if no user-config value is found, we check the computed node value
      if !user_config.nil?
        user_config
      else
        service_status(service)
      end
    end

    private

    def cookbook_services(value = nil)
      @cookbook_services = value if value
      @cookbook_services ||= {}
    end

    # Reads/Writes the service enable value in the node.default attributes
    def service_status(service, value = nil)
      rservice = service.tr('_', '-')

      service_path = if Gitlab[:node]['monitoring']&.attribute?(rservice)
                       ['monitoring', rservice]
                     elsif Gitlab[:node].attribute?(rservice)
                       [rservice]
                     else
                       ['gitlab', rservice]
                     end

      if value.nil?
        Gitlab[:node].read(*service_path, 'enable')
      else
        Gitlab[:node].write(:default, *service_path, 'enable', value)
      end
    end

    def set_services_status(enable, *services, except: nil)
      exceptions = [except].flatten
      service_list.each do |name, _|
        # Set the service enable config if:
        #  The current service is not in the list of exceptions
        #  AND
        #  The current service was requested to be set, or ALL_SERVICES was
        #  requested, so we are setting them all
        service_status(name, enable) if !exceptions.include?(name) && (services.include?(ALL_SERVICES) || services.include?(name))
      end
    end

    def set_service_groups_status(enable, *groups, except: nil)
      exceptions = [except].flatten
      service_list.each do |name, service|
        # Find the matching groups among our passed arguments and our current service's groups
        matching_exceptions = exceptions & service[:groups]
        matching_groups = groups & service[:groups]

        # Set the service enable config if:
        #  The current service has no matching exceptions
        #  AND
        #  The current service has matching groups that were requested to be set,
        #  or ALL_GROUPS was requested, so we are setting them all
        service_status(name, enable) if matching_exceptions.empty? && (groups.include?(ALL_GROUPS) || !matching_groups.empty?)
      end
    end
  end
end unless defined?(Services) # Prevent reloading during converge, so we can test
