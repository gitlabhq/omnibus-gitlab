#
# Copyright 2012-2014 Chef Software, Inc.
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

name 'libxml2'
default_version '2.9.10'

license 'MIT'
license_file 'COPYING'

skip_transitive_dependency_licensing true

dependency 'zlib'
dependency 'libiconv'
dependency 'liblzma'
dependency 'config_guess'

version '2.9.10' do
  source sha256: 'aafee193ffb8fe0c82d4afef6ef91972cbaf5feea100edc2f262750611b4be1f'
end

source url: "ftp://xmlsoft.org/libxml2/libxml2-#{version}.tar.gz"

relative_path "libxml2-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  patch source: '50f06b3efb638efb0abd95dc62dca05ae67882c2.patch', env: env
  patch source: 'CVE-2019-20388.patch', env: env
  patch source: 'CVE-2020-7595.patch', env: env
  patch source: 'bf22713507fe1fc3a2c4b525cf0a88c2dc87a3a2.patch', env: env # CVE-2021-3517
  patch source: '1358d157d0bd83be1dfe356a69213df9fac0b539.patch', env: env # CVE-2021-3516
  patch source: '1098c30a040e72a4654968547f415be4e4c40fe7.patch', env: env # CVE-2021-3518
  patch source: 'babe75030c7f64a37826bb3342317134568bef61.patch', env: env # CVE-2021-3537
  patch source: '8598060bacada41a0eb09d95c97744ff4e428f8e.patch', env: env # CVE-2021-3541

  configure_command = [
    "--with-zlib=#{install_dir}/embedded",
    "--with-iconv=#{install_dir}/embedded",
    '--without-python',
    '--without-icu'
  ]

  update_config_guess

  configure(*configure_command, env: env)

  make "-j #{workers}", env: env
  make 'install', env: env
end

project.exclude 'embedded/lib/xml2Conf.sh'
project.exclude 'embedded/bin/xml2-config'
project.exclude 'embedded/lib/cmake/libxml2/libxml2-config.cmake'
