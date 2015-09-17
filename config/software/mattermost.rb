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
default_version "v0.7.1"

source url: "https://github.com/mattermost/platform/releases/download/#{version}/mattermost.tar.gz",
       md5: '644bfdec4664c39597e04e57584afa60'

build do
  move "bin/platform", "#{install_dir}/embedded/bin/mattermost"

  command "mkdir -p #{install_dir}/embedded/service/mattermost"
  command "#{install_dir}/embedded/bin/rsync -a --delete ./api/templates #{install_dir}/embedded/service/mattermost/api/"
  command "#{install_dir}/embedded/bin/rsync -a --delete ./web/static #{install_dir}/embedded/service/mattermost/web/"
  command "#{install_dir}/embedded/bin/rsync -a --delete ./web/templates #{install_dir}/embedded/service/mattermost/web/"

  block do
    license_name = "GITLAB-MATTERMOST-COMPILED-LICENSE.txt"
    license_path = File.join(install_dir, "embedded/service/mattermost", license_name)

    File.open(license_path, 'w') { |f| f.write(GITLAB_MATTERMOST_COMPILED_LICENSE) }
  end
end

GITLAB_MATTERMOST_COMPILED_LICENSE = <<-EOH

GitLab Mattermost Compiled License
(MIT with Trademark Protection)

**Note: this license does not cover source code, for information on source code licensing see http://www.mattermost.org/license/

Copyright (c) 2015 Spinpunch, Inc.
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software;
The receiver of the Software will not remove or alter any product identification, trademark, copyright or other notices embedded within or appearing within or on the Software;

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

EOH
