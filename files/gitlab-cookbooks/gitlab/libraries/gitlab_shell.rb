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

module GitlabShell
  class << self
    def parse_variables
      parse_git_data_dirs
      parse_auth_file
    end

    def parse_git_data_dirs
      git_data_dirs = Gitlab['git_data_dirs']
      git_data_dir = Gitlab['git_data_dir']
      return unless git_data_dirs.any? || git_data_dir

      Gitlab['gitlab_shell']['git_data_directories'] ||=
        if git_data_dirs.any?
          git_data_dirs
        else
          { 'default' => git_data_dir }
        end

      Gitlab['gitlab_rails']['repositories_storages'] ||=
        Hash[Gitlab['gitlab_shell']['git_data_directories'].map do |name, path|
          [name, File.join(path, 'repositories')]
        end]

      # Important: keep the satellites.path setting until GitLab 9.0 at
      # least. This setting is fed to 'rm -rf' in
      # db/migrate/20151023144219_remove_satellites.rb
      Gitlab['gitlab_rails']['satellites_path'] ||= File.join(Gitlab['gitlab_shell']['git_data_directories']['default'], "gitlab-satellites")
    end

    def parse_auth_file
      Gitlab['user']['home'] ||=  Gitlab['node']['gitlab']['user']['home']
      Gitlab['gitlab_shell']['auth_file'] ||=  File.join(Gitlab['user']['home'], '.ssh', 'authorized_keys')
    end
  end
end
