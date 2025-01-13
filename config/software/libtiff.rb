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

name 'libtiff'
version = Gitlab::Version.new('libtiff', 'v4.7.0')

default_version version.print(false)

license 'libtiff' # BSD-3 Clause compatible
license_file 'COPYRIGHT'

skip_transitive_dependency_licensing true

dependency 'libtool'
dependency 'zlib'
dependency 'liblzma'
dependency 'libjpeg-turbo'
dependency 'config_guess'

source git: version.remote

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # Patch the code to download config.guess and config.sub. We instead copy
  # the ones we vendor to the correct location.
  patch source: 'remove-config-guess-sub-download.patch'

  command './autogen.sh', env: env
  update_config_guess(target: 'config')

  configure_command = [
    './configure',
    '--disable-zstd',
    "--prefix=#{install_dir}/embedded"
  ]

  command configure_command.join(' '), env: env

  make "-j #{workers} install", env: env
end
