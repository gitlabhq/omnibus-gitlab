#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

name 'pgbouncer'
version = Gitlab::Version.new('pgbouncer', 'pgbouncer_1_23_1')
default_version version.print(false)

license 'ISC'
license_file 'COPYRIGHT'

skip_transitive_dependency_licensing true

dependency 'libevent'
dependency 'openssl' unless Build::Check.use_system_ssl?

source git: version.remote

build do
  env = with_standard_compiler_flags(with_embedded_path)
  cwd = "#{Omnibus::Config.source_dir}/pgbouncer"

  command %w[git submodule init], cwd: cwd
  command %w[git submodule update], cwd: cwd
  command './autogen.sh', env: env, cwd: cwd

  prefix = "#{install_dir}/embedded"
  configure_command = ["./configure", "--prefix=#{prefix}", "--with-libevent=#{prefix}"]
  configure_command << "--with-openssl=#{prefix}" unless Build::Check.use_system_ssl?
  command configure_command.join(' '), env: env, cwd: cwd

  # Disable building of docs to avoid the need for pandoc
  command 'sed -i -e "/^dist_man_MANS =/d" Makefile', env: env, cwd: cwd

  make "-j #{workers}", env: env, cwd: cwd
  make 'install', env: env, cwd: cwd
end
