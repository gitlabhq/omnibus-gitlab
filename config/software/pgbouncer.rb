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
default_version '1.7.2'

license 'ISC'
license_file 'COPYRIGHT'

dependency 'libevent'
dependency 'openssl'

version '1.7.2' do
  source sha256: 'de36b318fe4a2f20a5f60d1c5ea62c1ca331f6813d2c484866ecb59265a160ba'
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
