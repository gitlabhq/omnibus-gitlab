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

module RolesHelper
  class << self
    def parse_enabled
      return unless Gitlab['roles']

      # convert hyphens to underscores to avoid user errors
      # split or space or comma (allow both to avoid user errors)
      active        = [Gitlab['roles']].flatten.map { |role| SettingsDSL::Utils.underscored_form(role) }
      valid_roles   = Gitlab.available_roles.keys.map { |key| "#{key}_role" }
      invalid_roles = active - valid_roles

      # Ensure all active roles exist as valid role names
      raise "The following invalid roles have been set in 'roles': #{invalid_roles.join(', ')}" unless invalid_roles.empty?

      active.each { |role_name| Gitlab[role_name]['enable'] = true }
    end
  end
end
