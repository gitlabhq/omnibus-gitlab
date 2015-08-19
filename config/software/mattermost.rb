#
## Copyright:: Copyright (c) 2015 GitLab B.V.
## License:: Apache License, Version 2.0
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

name "mattermost"
default_version "v0.6.0"

source url: "https://github.com/mattermost/platform/releases/download/#{version}/mattermost.tar.gz",
       md5: '9731b432644862d2025c68afabc852f5'

build do
  move "bin/platform", "#{install_dir}/embedded/bin/mattermost"

  command "mkdir -p #{install_dir}/embedded/service/mattermost"
  command "#{install_dir}/embedded/bin/rsync -a --delete ./api/templates #{install_dir}/embedded/service/mattermost/api/"
  command "#{install_dir}/embedded/bin/rsync -a --delete ./web/static #{install_dir}/embedded/service/mattermost/web/"
  command "#{install_dir}/embedded/bin/rsync -a --delete ./web/templates #{install_dir}/embedded/service/mattermost/web/"
end
