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

module DefaultRole
  class << self
    def load_role
      # Default role is only enabled if no other service role is enabled
      return unless no_service_roles_enabled?

      service_exclusions = []
      service_exclusions << 'rails' if Gitlab['gitlab_rails']['enable'] == false

      Services.enable_group(Services::DEFAULT_GROUP, except: service_exclusions)
    end

    def no_service_roles_enabled?
      Gitlab.available_roles.select { |key, role| role[:manage_services] && Gitlab["#{key}_role"]['enable'] }.count.zero?
    end
  end
end unless defined?(DefaultRole) # Prevent reloading during converge, so we can test
