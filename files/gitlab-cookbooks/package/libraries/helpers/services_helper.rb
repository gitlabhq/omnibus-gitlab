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

require_relative '../settings_dsl.rb'

module Services
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
    # Excludes the groups provided in the *except* argument
    # System services are ignored when disabling unless *include_system* is *true*.
    #
    # @example usage
    #   Services.disable_group('redis')
    #   Services.disable_group('monitoring', except: ['redis', 'postgres'])
    #   Services.disable_group(Services::ALL_GROUPS, except: 'redis')
    #
    # @param [Array] groups
    # @param [Array<String>, String] except
    # @param [Boolean] include_system
    def disable_group(*groups, except: nil, include_system: false)
      exceptions = [except].flatten
      exceptions << SYSTEM_GROUP unless include_system

      set_service_groups_status(false, *groups, except: exceptions)
    end

    # Enables the group of services that were passed as arguments
    #
    # Excludes the groups provided in the *except* argument
    #
    # @example usage
    #   Services.enable_group('redis')
    #   Services.enable_group('monitoring', except: ['redis', 'postgres'])
    #   Services.enable_group(Services::DEFAULT_GROUP, except: 'redis')
    # @param [Array] groups
    # @param [Array<String>, String] except
    def enable_group(*groups, except: nil)
      set_service_groups_status(true, *groups, except: except)
    end

    # Disables the services that were passed as arguments
    #
    # Excludes the services provided in the *except* argument
    # System services are ignored when disabling unless *include_system* is *true*.
    #
    # @example usage
    #   Services.disable('mailroom')
    #   Services.disable(Services::ALL_SERVICES, except: ['redis', 'sentinel'])
    #
    # @param [Array] services
    # @param [Array<String>, String] except
    # @param [Boolean] include_system
    def disable(*services, except: nil, include_system: false)
      # Automatically excludes system services unless `include_system: true` is passed
      exceptions = [*except]
      exceptions.concat(system_services) unless include_system

      set_services_status(false, *services, except: exceptions)
    end

    # Enables the services that were passed as arguments
    #
    # Excludes the services provided in the *except* argument
    #
    # @example usage
    #   Services.enable('mailroom')
    #   Services.enable(Services::ALL_SERVICES, except: ['monitoring'])
    #
    # @param [Array] services
    # @param [Array<String>, String] except
    def enable(*services, except: nil)
      set_services_status(true, *services, except: except)
    end

    # Sets the enable status on the services that were passed as arguments
    #
    # Excludes the service provided in the *except* argument.
    # System services are ignored when disabling unless *include_system* is *true*.
    #
    # @param [Array] services
    # @param [Boolean] enable
    # @param [Array<String>, String] except
    # @param [Boolean] include_system
    def set_status(*services, enable, except: nil, include_system: false)
      if enable
        enable(*services, except: except)
      else
        disable(*services, except: except, include_system: include_system)
      end
    end

    # Sets the enable status on the service groups that were passed as arguments
    #
    # Excludes the service groups provided in the *except* argument
    # System services are ignored when disabling unless *include_system* is *true*.
    #
    # @param [Array] groups
    # @param [Boolean] enable
    # @param [Array<String>, String] except
    # @param [Boolean] include_system
    def set_group_status(*groups, enable, except: nil, include_system: false)
      if enable
        enable_group(*groups, except: except)
      else
        disable_group(*groups, except: except, include_system: include_system)
      end
    end

    # Return a list of system services
    #
    # @return [Array] list of services
    def system_services
      find_by_group(SYSTEM_GROUP)
    end

    # Find services by group
    #
    # @param [String] group
    # @return [Array] list of services
    def find_by_group(group)
      service_list.select { |_, metadata| metadata[:groups].include?(group) }.keys
    end

    # List known services along with its associated `groups` metadata
    #
    # @return [Hash]
    def service_list
      @service_list ||= {}
    end

    # Add services from cookbooks
    #
    # @example usage
    #   Services.add_services('gitlab', Services::BaseServices.list)
    #
    # @param [String] cookbook
    # @param [Hash] services
    def add_services(cookbook, services)
      cookbook_services[cookbook] = services
      service_list.merge!(services)
    end

    # Reset stored cookbooks and their related services
    #
    # @note This is intended to be used in test environment only!
    def reset_list!
      @cookbook_services = nil
      @service_list = nil
    end

    # Return whether a service is enabled or not
    #
    # If service status is set via configuration file that takes precedence, otherwise we
    # use the computed value instead
    #
    # @param [String] service
    # @return [Boolean] whether is enabled or not
    def enabled?(service)
      return false unless exist?(service)

      user_config = Gitlab[service]['enable']

      return user_config unless user_config.nil?

      service_status(service)
    end

    # Return whether a specific service exist
    #
    # @note In CE distributions, some services may not exist as they are EE only
    # @return [Boolean] whether service exist or not
    def exist?(service)
      !service_list[service].nil?
    end

    private

    def cookbook_services
      @cookbook_services ||= {}
    end

    # Return whether service is enabled or not
    #
    # @param [String] service
    # @return [Boolean] whether enabled or not
    def service_status(service)
      Gitlab[:node].read(*service_attribute_path(service), 'enable')
    end

    # Set service enabled/disabled status
    #
    # @param [String] service
    # @param [Boolean] enabled
    def set_service_status(service, enabled)
      Gitlab[:node].write(:default, *service_attribute_path(service), 'enable', enabled)
    end

    # Return internal path to manipulate service attributes
    #
    # @param [String] service_name
    # @return [Array]
    def service_attribute_path(service_name)
      service = SettingsDSL::Utils.sanitized_key(service_name)

      return ['monitoring', service] if Gitlab[:node]['monitoring']&.attribute?(service)
      return [service] if Gitlab[:node].attribute?(service)

      ['gitlab', service]
    end

    # Set status for a list of services considering provided exceptions
    #
    # @param [Boolean] enable
    # @param [Array] services
    # @param [Array<String>, String] except
    def set_services_status(enable, *services, except: nil)
      exceptions = [*except]

      service_list.each do |name, _|
        # Skip if service is in exceptions list
        next if exceptions.include?(name)

        # Skip if service does not *exist?*
        next unless exist?(name)

        # Set the service enable config if:
        #  The current service was requested to be set
        #  OR
        #  ALL_SERVICES was requested, so we are setting them all
        set_service_status(name, enable) if services.include?(name) || services.include?(ALL_SERVICES)
      end
    end

    # Set status for services related with provided groups considering provided exceptions
    #
    # @param [Boolean] enable
    # @param [Array] groups
    # @param [Array<String>, String] except
    def set_service_groups_status(enable, *groups, except: nil)
      exceptions = [*except]

      service_list.each do |name, metadata|
        # Skip if service is in exceptions list
        next if (exceptions & metadata[:groups]).any?

        # Skip if service does not *exist?*
        next unless exist?(name)

        # Find the matching groups among our passed arguments and our current service's groups
        matching_groups = groups & metadata[:groups]

        # Set the service enable config if:
        # The current service has matching groups that were requested to be set
        # OR
        # ALL_GROUPS was requested, so we are setting them all
        set_service_status(name, enable) if matching_groups.any? || groups.include?(ALL_GROUPS)
      end
    end
  end
end
