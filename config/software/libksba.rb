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

name 'libksba'
default_version '1.6.3'

dependency 'libgpg-error'

license 'LGPL-3'
license_file 'COPYING.LGPLv3'

skip_transitive_dependency_licensing true

source url: "https://www.gnupg.org/ftp/gcrypt/libksba/libksba-#{version}.tar.bz2",
       sha256: '3f72c68db30971ebbf14367527719423f0a4d5f8103fc9f4a1c01a9fa440de5c'

relative_path "libksba-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  command './configure ' \
    "--prefix=#{install_dir}/embedded --disable-doc", env: env

  make "-j #{workers}", env: env
  make 'install', env: env
end

project.exclude "embedded/bin/ksba-config"
