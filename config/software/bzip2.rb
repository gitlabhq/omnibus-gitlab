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
# Install bzip2 and its shared library, libbz2.so
# This library object is required for building Python with the bz2 module,
# and should be picked up automatically when building Python.

name 'bzip2'
default_version '1.0.6'

license 'BSD-2-Clause'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'zlib'
dependency 'openssl' unless Build::Check.use_system_ssl?

version '1.0.6' do
  source md5: '00b516f4704d4a7cb50a1d97e6e8e15b'
end
source url: "https://sourceware.org/pub/bzip2/#{name}-#{version}.tar.gz"

relative_path "#{name}-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # Avoid warning where .rodata cannot be used when making a shared object
  env['CFLAGS'] << ' -fPIC'

  # The list of arguments to pass to make
  args = "PREFIX='#{install_dir}/embedded' VERSION='#{version}'"

  patch source: 'makefile_take_env_vars.patch', env: env
  patch source: 'CVE-2016-3189.patch', env: env

  make args.to_s, env: env
  make "#{args} -f Makefile-libbz2_so", env: env
  make "#{args} install", env: env
end
