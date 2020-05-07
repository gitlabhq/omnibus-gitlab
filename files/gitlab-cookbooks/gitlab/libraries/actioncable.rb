#
# Copyright:: Copyright (c) 2020 GitLab Inc.
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

module ActionCable
  class << self
    def parse_variables
      parse_actioncable_listen_address
    end

    def parse_actioncable_listen_address
      actioncable_socket = Gitlab['actioncable']['socket'] || Gitlab['node']['gitlab']['actioncable']['socket']

      # The user has no custom settings for connecting Workhorse to ActionCable.
      # Let's do what we think is best.
      Gitlab['gitlab_workhorse']['cable_socket'] = actioncable_socket if Gitlab['gitlab_workhorse']['cable_backend'].nil?
    end
  end
end
