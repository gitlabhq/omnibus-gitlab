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
default_version '1.8.1'

license 'ISC'
license_file 'COPYRIGHT'

dependency 'libevent'
dependency 'openssl'

version '1.8.1' do
  source sha256: 'fa8bde2a2d2c8c80d53a859f8e48bc6713cf127e31c77d8f787bbc1d673e8dc8'
end

source url: "https://pgbouncer.github.io/downloads/files/#{version}/pgbouncer-#{version}.tar.gz"

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
