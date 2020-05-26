#
# Copyright:: Copyright (c) 2020 GitLab Inc.
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

name 'libjpeg-turbo'

version = Gitlab::Version.new('libjpeg-turbo', '2.0.4')

default_version version.print(false)

license 'BSD-3-Clause'
license_file 'LICENSE.md'
license_file 'README.ijg'

dependency 'zlib'

source git: version.remote

build do
  env = with_standard_compiler_flags(with_embedded_path)

  configure_command = [
    'cmake',
    '-G"Unix Makefiles"',
    "-DCMAKE_INSTALL_LIBDIR:PATH=lib", # ensure lib64 isn't used
    "-DCMAKE_INSTALL_PREFIX=#{install_dir}/embedded"
  ]

  command configure_command.join(' '), env: env

  make "-j #{workers} install", env: env
end
