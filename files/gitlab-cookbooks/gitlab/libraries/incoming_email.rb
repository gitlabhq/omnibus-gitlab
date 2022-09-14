#
# Copyright:: Copyright (c) 2016 GitLab Inc.
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

module IncomingEmail
  class << self
    def parse_variables
      parse_incoming_email || parse_service_desk_email
    end

    def parse_secrets
      # mailroom expects exactly 32 bytes, encoded with base64

      # rubocop:disable Style/IfUnlessModifier,Style/GuardClause
      if rails_user_config_or_default('incoming_email_enabled') && rails_user_config_or_default('incoming_email_delivery_method') == "webhook"
        Gitlab['mailroom']['incoming_email_auth_token'] ||= Gitlab['gitlab_rails']['incoming_email_auth_token'] || SecretsHelper.generate_base64(32)
      end

      if rails_user_config_or_default('service_desk_email_enabled') && rails_user_config_or_default('service_desk_email_delivery_method') == "webhook"
        Gitlab['mailroom']['service_desk_email_auth_token'] ||= Gitlab['gitlab_rails']['service_desk_email_auth_token'] || SecretsHelper.generate_base64(32)
      end
      # rubocop:enable Style/IfUnlessModifier,Style/GuardClause
    end

    def parse_incoming_email
      return unless Gitlab['gitlab_rails']['incoming_email_enabled']

      Gitlab['mailroom']['enable'] = true if Gitlab['mailroom']['enable'].nil?
    end

    def parse_service_desk_email
      return unless Gitlab['gitlab_rails']['service_desk_email_enabled']

      Gitlab['mailroom']['enable'] = true if Gitlab['mailroom']['enable'].nil?
    end

    private

    def default_rails_config
      Gitlab['node']['gitlab']['gitlab-rails']
    end

    def user_rails_config
      Gitlab['gitlab_rails']
    end

    def rails_user_config_or_default(key)
      # Note that we must not use an `a || b`` truthiness check here since that would mean a `false`
      # user setting would fail over to the default, which is not what we want.
      user_rails_config[key].nil? ? default_rails_config[key] : user_rails_config[key]
    end
  end
end
