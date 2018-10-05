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

source url: "https://github.com/jemalloc/jemalloc/releases/download/#{version}/jemalloc-#{version}.tar.bz2",
       sha256: '5630650d5c1caab95d2f0898de4fe5ab8519dc680b04963b38bb425ef6a42d57'

dependency 'redis'

env = with_standard_compiler_flags(with_embedded_path)

relative_path "jemalloc-#{version}"

build do
  command ['./configure',
           ' --enable-cc-silence',
           ' --enable-prof',
           "--prefix=#{install_dir}/embedded"].join(' '), env: env
  make "-j #{workers}", env: env
  make 'install', env: env
end

project.exclude "embedded/bin/jemalloc-config"
