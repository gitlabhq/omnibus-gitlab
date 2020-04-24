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

    def parse_incoming_email
      return unless Gitlab['gitlab_rails']['incoming_email_enabled']

      Gitlab['mailroom']['enable'] = true if Gitlab['mailroom']['enable'].nil?
    end

    def parse_service_desk_email
      return unless Gitlab['gitlab_rails']['service_desk_email_enabled']

      Gitlab['mailroom']['enable'] = true if Gitlab['mailroom']['enable'].nil?
    end
  end
end
