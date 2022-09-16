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

name 'libedit'
default_version '20120601-3.0'

license 'BSD-3-Clause'
license_file 'COPYING'

skip_transitive_dependency_licensing true

dependency 'ncurses'
dependency 'config_guess'

version('20120601-3.0') { source sha256: '51f0f4b4a97b7ebab26e7b5c2564c47628cdb3042fd8ba8d0605c719d2541918' }

source url: "http://www.thrysoee.dk/editline/libedit-#{version}.tar.gz"

if version == '20141030-3.1'
  # released tar file has name discrepency in folder name for this version
  relative_path 'libedit-20141029-3.1'
else
  relative_path "libedit-#{version}"
end

build do
  env = with_standard_compiler_flags(with_embedded_path)

  update_config_guess

  command './configure' \
          " --prefix=#{install_dir}/embedded", env: env

  make "-j #{workers}", env: env
  make "-j #{workers} install", env: env
end
