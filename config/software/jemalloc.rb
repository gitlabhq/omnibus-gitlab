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

name 'jemalloc'
default_version '4.2.1'

license 'jemalloc'
license_file 'COPYING'

skip_transitive_dependency_licensing true

source git: 'https://github.com/jemalloc/jemalloc'

dependency 'redis'

env = with_standard_compiler_flags(with_embedded_path)

relative_path "jemalloc-#{version}"

build do
  command ['./autogen.sh',
           ' --enable-cc-silence',
           ' --enable-prof',
           "--prefix=#{install_dir}/embedded"].join(' '), env: env
  make "-j #{workers} build_lib", env: env
  make 'install_lib', env: env
  make 'install_bin', env: env
end

project.exclude "embedded/bin/jemalloc-config"
