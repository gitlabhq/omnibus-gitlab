#
# Copyright 2012-2018 Chef Software, Inc.
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

name 'zlib'
version = Gitlab::Version.new('zlib', 'v1.2.11')
default_version version.print(false)

source git: version.remote

license 'Zlib'
license_file 'README'
skip_transitive_dependency_licensing true

build do
  # We omit the omnibus path here because it breaks mac_os_x builds by picking
  # up the embedded libtool instead of the system libtool which the zlib
  # configure script cannot handle.
  # TODO: Do other OSes need this?  Is this strictly a mac thing?
  env = with_standard_compiler_flags

  configure env: env

  make "-j #{workers}", env: env
  make "-j #{workers} install", env: env
end
