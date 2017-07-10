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

require_relative 'base_services.rb'

class Services < BaseServices
  # Define all gitlab cookbook services
  core_services(
    'logrotate' =>          svc(groups: [DEFAULT_GROUP, SYSTEM_GROUP]),
    'node_exporter' =>      svc(groups: [DEFAULT_GROUP, SYSTEM_GROUP, 'prometheus']),
    'gitlab_rails' =>       svc(groups: [DEFAULT_GROUP, 'rails']),
    'unicorn' =>            svc(groups: [DEFAULT_GROUP, 'rails']),
    'sidekiq' =>            svc(groups: [DEFAULT_GROUP, 'rails', 'sidekiq']),
    'gitlab_monitor' =>     svc(groups: [DEFAULT_GROUP, 'rails', 'prometheus']),
    'gitlab_workhorse' =>   svc(groups: [DEFAULT_GROUP, 'rails']),
    'redis' =>              svc(groups: [DEFAULT_GROUP, 'redis']),
    'redis_exporter' =>     svc(groups: [DEFAULT_GROUP, 'redis', 'prometheus']),
    'gitaly' =>             svc(groups: [DEFAULT_GROUP]),
    'postgresql' =>         svc(groups: [DEFAULT_GROUP, 'postgres']),
    'nginx' =>              svc(groups: [DEFAULT_GROUP]),
    'prometheus' =>         svc(groups: [DEFAULT_GROUP, 'prometheus']),
    'postgres_exporter' =>  svc(groups: [DEFAULT_GROUP, 'prometheus', 'postgres']),
    'mailroom' =>           svc,
    'gitlab_pages' =>       svc,
    'mattermost' =>         svc,
    'mattermost_nginx' =>   svc,
    'pages_nginx' =>        svc,
    'registry' =>           svc
  )

  class << self
    # Disables the group of services that were passed as arguments, or all
    # services if no services are provided
    #
    # Excludes the group, or array of groups, provided in the `except` argument
    # ex: Services.disable_group('redis')
    #     Services.disable_group('prometheus' except: ['redis', 'postgres'])
    #     Services.disable_group(except: 'redis')
    def disable_group(*groups, except: nil, include_system: false)
      exceptions = [except].flatten
      exceptions << BaseServices::SYSTEM_GROUP unless include_system
      set_enabled_group(false, *groups, except: exceptions)
    end

    # Enables the group of services that were passed as arguments, or all
    # services if no services are provided
    #
    # Excludes the group, or array of groups, provided in the `except` argument
    # ex: Services.enable_group('redis')
    #     Services.enable_group('prometheus' except: ['redis', 'postgres'])
    #     Services.enable_group(except: 'redis')
    def enable_group(*groups, except: nil)
      set_enabled_group(true, *groups, except: except)
    end

    # Disables the services that were passed as arguments, or all services if
    # no services are provided
    #
    # Excludes the service, or array of services, provided in the `except` argument
    # ex: Services.disable('mailroom')
    #     Services.disable(except: ['redis', 'sentinel'])
    def disable(*services, except: nil, include_system: false)
      # Automatically excludes system services unless `include_system: true` is passed
      exceptions = [except].flatten
      exceptions.concat(system_services.keys) unless include_system

      set_enabled(false, *services, except: exceptions)
    end

    # Enables the services that were passed as arguments, or all services if
    # no services are provided
    #
    # Excludes the service, or array of services, provided in the `except` argument
    # ex: Services.enable('mailroom')
    #     Services.enable(except: ['prometheus'])
    def enable(*services, except: nil)
      set_enabled(true, *services, except: except)
    end

    def system_services
      find_by_group(BaseServices::SYSTEM_GROUP)
    end

    def find_by_group(group)
      service_list.select { |name, service| service[:groups].include?(group) }
    end

    private

    def set_enabled(enable, *services, except: nil)
      exceptions = [except].flatten
      service_list.each do |name, _|
        # Set the service enable config if:
        #  The current service is not in the list of exceptions
        #  AND
        #  The current service was requested to be set, or no specific service was
        #  requested, so we are setting them all
        if !exceptions.include?(name) && (services.empty? || services.include?(name))
          Gitlab[name]['enable'] = enable
        end
      end
    end

    def set_enabled_group(enable, *groups, except: nil)
      exceptions = [except].flatten
      service_list.each do |name, service|
        # Find the matching groups among our passed arguments and our current service's groups
        matching_exceptions = exceptions & service[:groups]
        matching_groups = groups & service[:groups]

        # Set the service enable config if:
        #  The current service has no matching exceptions
        #  AND
        #  The current service has matching groups that were requested to be set,
        #  or no specific group was requested, so we are setting them all
        if matching_exceptions.empty? && (groups.empty? || !matching_groups.empty?)
          Gitlab[name]['enable'] = enable
        end
      end
    end
  end
end unless defined?(Services) # Prevent reloading during converge, so we can test
