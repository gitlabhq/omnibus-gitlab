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
    def system_services
      find_by_group(BaseServices::SYSTEM_GROUP)
    end

    def disable(*services, except: nil, force: false)
      exceptions = [except].flatten
      exceptions.concat(system_services.keys) unless force
      set_enabled(false, *services, except: exceptions)
    end

    def enable(*services, except: nil)
      set_enabled(true, *services, except: except)
    end

    def disable_group(*groups, except: nil, force: false)
      exceptions = [except].flatten
      exceptions << BaseServices::SYSTEM_GROUP unless force
      set_enabled_group(false, *groups, except: exceptions)
    end

    def enable_group(*groups, except: nil)
      set_enabled_group(true, *groups, except: except)
    end

    def find_by_group(group)
      service_list.select { |name, service| service[:groups].include?(group) }
    end

    private

    def set_enabled(enable, *services, except: nil)
      exceptions = [except].flatten
      service_list.each do |name, _|
        if (services.empty? || services.include?(name)) && !exceptions.include?(name)
          Gitlab[name]['enable'] = enable
        end
      end
    end

    def set_enabled_group(enable, *groups, except: nil)
      exceptions = [except].flatten
      service_list.each do |name, service|
        if (groups.empty? || !(groups & service[:groups]).empty?) && (exceptions & service[:groups]).empty?
          Gitlab[name]['enable'] = enable
        end
      end
    end
  end
end unless defined?(Services) # Prevent reloading during converge, so we can test
