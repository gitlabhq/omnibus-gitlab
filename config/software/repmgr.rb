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

name 'repmgr'
version = Gitlab::Version.new('repmgr', 'v3.3.2')

default_version version.print(false)

license 'GPL-3.0'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

source git: version.remote

dependency 'postgresql'

env = with_standard_compiler_flags(with_embedded_path)

build do
  env['PATH'] = "#{install_dir}/embedded/postgresql/11/bin:#{env['PATH']}"

  patch source: 'modules_big.patch', env: env

  make "-j #{workers} USE_PGXS=1 all", env: env
  make "-j #{workers} USE_PGXS=1 install", env: env
end
