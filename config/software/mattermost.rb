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

name 'mattermost'
default_version '5.28.1'

source url: "https://releases.mattermost.com/#{version}/mattermost-team-#{version}-linux-amd64.tar.gz",
       md5: '122ee1b798b716333942097b48c01f3f'

relative_path 'mattermost'

license_name = 'GITLAB-MATTERMOST-COMPILED-LICENSE.txt'
license_path = File.join(install_dir, 'embedded/service/mattermost', license_name)

license 'MIT with Trademark Protection'
license_file license_path

skip_transitive_dependency_licensing true

build do
  move 'bin/mattermost', "#{install_dir}/embedded/bin/mattermost"

  command "mkdir -p #{install_dir}/embedded/service/mattermost"
  copy 'templates', "#{install_dir}/embedded/service/mattermost/templates"
  copy 'i18n', "#{install_dir}/embedded/service/mattermost/i18n"
  copy 'fonts', "#{install_dir}/embedded/service/mattermost/fonts"
  copy 'client', "#{install_dir}/embedded/service/mattermost/client"
  copy 'config/config.json', "#{install_dir}/embedded/service/mattermost/config.json.template"
  copy 'prepackaged_plugins', "#{install_dir}/embedded/service/mattermost/prepackaged_plugins"

  block do
    File.write(license_path, GITLAB_MATTERMOST_COMPILED_LICENSE)
    File.write(File.join(install_dir, 'embedded/service/mattermost/VERSION'), version)
  end
end

GITLAB_MATTERMOST_COMPILED_LICENSE = <<-EOH.freeze

GitLab Mattermost Compiled License
(MIT with Trademark Protection)

**Note: this license does not cover source code, for information on source code licensing see http://www.mattermost.org/license/

Copyright (c) 2015 Mattermost, Inc.
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software;
The receiver of the Software will not remove or alter any product identification, trademark, copyright or other notices embedded within or appearing within or on the Software;

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

EOH
