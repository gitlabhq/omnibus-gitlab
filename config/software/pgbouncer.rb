#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

name 'pgbouncer'
default_version '1.12.0'

license 'ISC'
license_file 'COPYRIGHT'

skip_transitive_dependency_licensing true

dependency 'libevent'
dependency 'openssl'

version '1.12.0' do
  source sha256: '1b3c6564376cafa0da98df3520f0e932bb2aebaf9a95ca5b9fa461e9eb7b273e'
end

source url: "https://www.pgbouncer.org/downloads/files/#{version}/pgbouncer-#{version}.tar.gz"

relative_path "pgbouncer-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  prefix = "#{install_dir}/embedded"

  command './configure ' \
    "--prefix=#{prefix} " \
    "--with-openssl=#{prefix} " \
    "--with-libevent=#{prefix}", env: env

  make "-j #{workers}", env: env
  make 'install', env: env
end
