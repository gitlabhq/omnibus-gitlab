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

name 'popt'
default_version '1.16'

license 'MIT'
license_file 'COPYING'

skip_transitive_dependency_licensing true

dependency 'config_guess'

source url: "https://ftp.osuosl.org/pub/blfs/conglomeration/popt/popt-#{version}.tar.gz",
       sha256: 'e728ed296fe9f069a0e005003c3d6b2dde3d9cad453422a10d6558616d304cc8'

relative_path "popt-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  update_config_guess

  # --disable-nls => Disable localization support.
  command './configure' \
          " --prefix=#{install_dir}/embedded" \
          ' --disable-nls', env: env

  make "-j #{workers}", env: env
  make 'install', env: env
end
