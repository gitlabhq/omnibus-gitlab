#
# Copyright 2014 Chef Software, Inc.
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

name 'liblzma'
default_version '5.2.4'

license 'Public-Domain'
license_file 'COPYING'

skip_transitive_dependency_licensing true

source url: "http://tukaani.org/xz/xz-#{version}.tar.gz",
       sha256: 'b512f3b726d3b37b6dc4c8570e137b9311e7552e8ccbab4d39d47ce5f4177145'

relative_path "xz-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  config_command = [
    '--disable-debug',
    '--disable-dependency-tracking',
    '--disable-doc',
    '--disable-scripts'
  ]

  configure(*config_command, env: env)

  make 'install', env: env
end
