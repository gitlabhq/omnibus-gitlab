#
## Copyright:: Copyright (c) 2014-2020 GitLab Inc.
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

name 'python-docutils'

default_version '0.16'

license 'Public-Domain'
license_file 'COPYING.txt'

skip_transitive_dependency_licensing true

dependency 'python3'

build do
  patch source: "license/#{version}/add-license-file.patch"
  env = with_standard_compiler_flags(with_embedded_path)
  command "#{install_dir}/embedded/bin/pip3 install --compile docutils==#{version}", env: env
end
