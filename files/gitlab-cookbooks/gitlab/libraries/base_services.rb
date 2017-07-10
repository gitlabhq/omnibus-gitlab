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

class BaseServices
  SYSTEM_GROUP = 'system'.freeze
  DEFAULT_GROUP = 'default'.freeze

  class << self
    def svc(config = {})
      # A service config object always needs a group array
      { groups: [] }.merge(config)
    end

    def service_list
      # Merge together and cache all the service lists (from the different cookbooks)
      @service_list ||= [core_services.dup, *other_services.dup.values].inject(&:merge)
    end

    def include_services(cookbook, services)
      # Add services from other cookbooks
      other_services[cookbook] = services
    end

    def reset_list
      # Remove additional services
      @other_services = nil

      # Clear the cached service list so it
      @service_list = nil
    end

    private

    def core_services(value = nil)
      @core_services = value if value
      @core_services ||= {}
    end

    def other_services(value = nil)
      @other_services = value if value
      @other_services ||= {}
    end
  end
end unless defined?(BaseServices) # Prevent reloading during converge, so we can test
