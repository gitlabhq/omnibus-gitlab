#
# Copyright:: Chef Software Inc.
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
default_version '2.9.14'

license 'MIT'
license_file 'COPYING'
skip_transitive_dependency_licensing true

dependency 'zlib'
dependency 'libiconv'
dependency 'liblzma'
dependency 'config_guess'

# version_list: url=https://download.gnome.org/sources/libxml2/2.9/ filter=*.tar.xz
version('2.9.14') { source sha256: '60d74a257d1ccec0475e749cba2f21559e48139efba6ff28224357c7c798dfee' }

source url: "https://download.gnome.org/sources/libxml2/2.9/libxml2-#{version}.tar.xz"

relative_path "libxml2-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  configure_command = [
    "--with-zlib=#{install_dir}/embedded",
    "--with-iconv=#{install_dir}/embedded",
    "--with-lzma=#{install_dir}/embedded",
    '--with-sax1', # required for nokogiri to compile
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
