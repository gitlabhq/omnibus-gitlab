#
# Copyright:: Copyright (c) 2014 GitLab B.V.
# License:: Apache License, Version 2.0
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

name 'krb5'

version = Gitlab::Version.new('krb5', 'krb5-1.17')

default_version version.print(false)
display_version version.print(false).delete_prefix('krb5-')

license 'MIT'
license_file 'NOTICE'

skip_transitive_dependency_licensing true

dependency 'openssl'

source git: version.remote

build do
  env = with_standard_compiler_flags(with_embedded_path)
  cwd = "#{Omnibus::Config.source_dir}/krb5/src"

  # Add configure option allowing libkeyutils to be disabled even if
  # it is detected
  #
  # TEMPORARY: 1.17 uses configure.in, but because autoconf is moving to
  # having this file named configure.ac, the upstream patches that now
  command "mv configure.in configure.ac", env: env, cwd: cwd
  patch source: 'Add-option-to-build-without-libkeyutils.patch'
  command "mv configure.ac configure.in", env: env, cwd: cwd

  command "autoreconf", env: env, cwd: cwd
  command './configure' \
           " --prefix=#{install_dir}/embedded --without-system-verto --without-keyutils --disable-pkinit", env: env, cwd: cwd

  make " -j #{workers}", env: env, cwd: cwd
  make 'install', env: env, cwd: cwd
end

project.exclude "embedded/bin/krb5-config"
