#
# Copyright:: Copyright (c) 2015 GitLab B.V.
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

class AccountHelper
  attr_reader :node

  def initialize(node)
    @node = node
  end

  def gitlab_user
    node['gitlab']['user']['username']
  end

  def gitlab_group
    node['gitlab']['user']['group']
  end

  def web_server_user
    node['gitlab']['web-server']['username']
  end

  def web_server_group
    node['gitlab']['web-server']['group']
  end

  def redis_user
    node['gitlab']['redis']['username']
  end

  def redis_group
    node['gitlab']['redis']['username']
  end

  def postgresgl_user
    node['gitlab']['postgresql']['username']
  end

  def postgresgl_group
    node['gitlab']['postgresql']['username']
  end

  def gitlab_ci_user
    node['gitlab']['gitlab-ci']['username']
  end

  def gitlab_ci_group
    node['gitlab']['gitlab-ci']['username']
  end

  def ci_redis_user
    node['gitlab']['ci-redis']['username']
  end

  def ci_redis_group
    node['gitlab']['ci-redis']['username']
  end

  def mattermost_user
    node['gitlab']['mattermost']['username']
  end

  def mattermost_group
    node['gitlab']['mattermost']['group']
  end

  def registry_user
    node['gitlab']['registry']['username']
  end

  def registry_group
    node['gitlab']['registry']['group']
  end

  def users
    %W(
        #{gitlab_user}
        #{web_server_user}
        #{redis_user}
        #{postgresgl_user}
        #{gitlab_ci_user}
        #{ci_redis_user}
        #{mattermost_user}
        #{registry_user}
      )
  end

  def groups
    %W(
        #{gitlab_group}
        #{web_server_group}
        #{redis_group}
        #{postgresgl_group}
        #{gitlab_ci_group}
        #{ci_redis_group}
        #{mattermost_group}
        #{registry_group}
      )
  end
end
