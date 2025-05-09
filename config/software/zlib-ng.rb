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

name 'zlib-ng'
version = Gitlab::Version.new('zlib-ng', '2.2.4')
default_version version.print(false)

source git: version.remote

license 'Zlib'
license_file 'LICENSE.md'
skip_transitive_dependency_licensing true

build do
  env = with_standard_compiler_flags

  # Default from `configure` in upstream zlib
  env['CFLAGS'] << ' -O3'

  # Enable frame-pointers to support profiling processes that
  # call this library's functions.
  env['CFLAGS'] << ' -fno-omit-frame-pointer'

  configure_command = [
    # Compile with zlib-compatible API.
    '--zlib-compat'
  ]

  configure(*configure_command, env: env)

  make "-j #{workers}", env: env
  make "-j #{workers} install", env: env
end
