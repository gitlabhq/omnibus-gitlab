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
version = Gitlab::Version.new('libtiff', 'v4.4.0')

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

  # Use cmake for CentOS 6 builds
  # CentOS 6 doesn't have a new enough version of automake, so we need to use
  # the cmake build steps, but the cmake steps aren't working properly in
  # Debian 8, which is why we don't just switch to cmake for all platforms
  if ohai['platform'] =~ /centos/ && ohai['platform_version'] =~ /^6/
    configure_command = [
      'cmake',
      '-G"Unix Makefiles"',
      '-Dzstd=OFF',
      "-DZLIB_ROOT=#{install_dir}/embedded",
      "-DCMAKE_INSTALL_LIBDIR:PATH=lib", # ensure lib64 isn't used
      "-DCMAKE_INSTALL_RPATH=#{install_dir}/embedded/lib",
      "-DCMAKE_FIND_ROOT_PATH=#{install_dir}/embedded",
      "-DCMAKE_PREFIX_PATH=#{install_dir}/embedded",
      "-DCMAKE_INSTALL_PREFIX=#{install_dir}/embedded"
    ]
  else
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
  end

  command configure_command.join(' '), env: env

  make "-j #{workers} install", env: env
end
