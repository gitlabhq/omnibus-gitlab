#
# Copyright:: Copyright (c) 2023 GitLab Inc.
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

name 'git-filter-repo'

version = Gitlab::Version.new('git-filter-repo', 'v2.38.0')
default_version version.print(false)

license 'MIT'
license_file 'COPYING'
license_file 'COPYING.gpl'
license_file 'COPYING.mit'

skip_transitive_dependency_licensing true

dependency 'git'
dependency 'python3'

build do
  env = with_standard_compiler_flags(with_embedded_path)

  patch source: "license/add-license-file.patch"
  patch source: "license/add-mit-license-file.patch"
  patch source: "license/add-gpl-license-file.patch"

  command "#{install_dir}/embedded/bin/pip3 install git-filter-repo==#{default_version}", env: env
end
