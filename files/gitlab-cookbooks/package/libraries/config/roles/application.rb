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

module ApplicationRole
  def self.load_role
    return unless Gitlab['application_role']['enable']

    Gitlab['gitlab_rails']['enable'] = true if Gitlab['gitlab_rails']['enable'].nil?

    service_exclusions = []
    # Certain services, like KAS doesn't work on FIPS environments. So we
    # disable it by default on FIPS environments.
    # Check https://gitlab.com/groups/gitlab-org/-/epics/7933 for details
    # about KAS.
    service_exclusions << 'skip_on_fips' if OpenSSL.fips_mode

    Services.enable_group('rails', except: service_exclusions)
  end
end
