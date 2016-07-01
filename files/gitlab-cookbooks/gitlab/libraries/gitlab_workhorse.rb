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

module GitlabWorkhorse
  class << self
    def parse_variables
      parse_gitlab_git_http_server
    end

    def parse_gitlab_git_http_server
      Gitlab['gitlab_git_http_server'].each do |k, v|
        Chef::Log.warn "gitlab_git_http_server is deprecated. Please use gitlab_workhorse in gitlab.rb"
        if Gitlab['gitlab_workhorse'][k].nil?
          Chef::Log.warn "applying legacy setting gitlab_git_http_server[#{k.inspect}]"
          Gitlab['gitlab_workhorse'][k] = v
        else
          Chef::Log.warn "ignoring legacy setting gitlab_git_http_server[#{k.inspect}]"
        end
      end
    end
  end
end
