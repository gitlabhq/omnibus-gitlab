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

default_version '1.14.2'

license 'MIT'
license_file 'NOTICE'

skip_transitive_dependency_licensing true

source url: "http://web.mit.edu/kerberos/dist/krb5/#{version.rpartition('.').first}/krb5-#{version}.tar.gz",
       sha256: '6bcad7e6778d1965e4ce4af21d2efdc15b274c5ce5c69031c58e4c954cda8b27'

relative_path "krb5-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  cwd = "#{Omnibus::Config.source_dir}/krb5/krb5-#{version}/src"

  # 'configure' will detect libkeyutils and set up the krb5 build
  # to link against it. This gives us trouble during the Omnibus 'health
  # check'. The patch below tries to corrupt 'configure' in such a way that
  # 'libkeyutils' will not get added.
  patch source: 'disable-keyutils.patch', target: 'src/configure'

  command './configure' \
           " --prefix=#{install_dir}/embedded --without-system-verto", env: env, cwd: cwd

  make " -j #{workers}", env: env, cwd: cwd
  make 'install', env: env, cwd: cwd
end

project.exclude "embedded/bin/krb5-config"
