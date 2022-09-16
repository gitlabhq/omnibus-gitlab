#
# Copyright 2013-2014 Chef Software, Inc.
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

name 'pkg-config-lite'
default_version '0.28-1'

license 'GPL-2.0'
license_file 'COPYING'

skip_transitive_dependency_licensing true

dependency 'config_guess'

version '0.28-1' do
  source sha256: '21b76ec4e115ee30f9b3077a2506e48e8b837332ed4d30c9776502e69c6a29e5'
end

source url: "https://downloads.sourceforge.net/project/pkgconfiglite/#{version}/pkg-config-lite-#{version}.tar.gz"

relative_path "pkg-config-lite-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  update_config_guess

  command './configure' \
          " --prefix=#{install_dir}/embedded" \
          ' --disable-host-tool' \
          " --with-pc-path=#{install_dir}/embedded/bin/pkgconfig", env: env

  make "-j #{workers}", env: env
  make "-j #{workers} install", env: env
end

project.exclude 'embedded/bin/pkg-config'
project.exclude 'embedded/lib/pkgconfig'
