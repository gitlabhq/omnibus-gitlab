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

name 'gnupg'
default_version '2.1.15'

dependency 'libassuan'
dependency 'npth'
dependency 'libgcrypt'
dependency 'libksba'
dependency 'zlib'

license 'LGPL-2.1'
license_file 'COPYING.LGPL3'

skip_transitive_dependency_licensing true

source url: "https://www.gnupg.org/ftp/gcrypt/gnupg/gnupg-#{version}.tar.bz2",
       sha256: 'c28c1a208f1b8ad63bdb6b88d252f6734ff4d33de6b54e38494b11d49e00ffdd'

relative_path "gnupg-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  command './configure ' \
    "--prefix=#{install_dir}/embedded --disable-doc --without-readline --disable-sqlite --disable-gnutls --disable-dirmngr", env: env

  make "-j #{workers}", env: env
  make 'install', env: env
end
