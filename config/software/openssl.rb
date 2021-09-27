#
# Copyright 2012-2019, Chef Software Inc.
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
require "#{Omnibus::Config.project_root}/lib/gitlab/ohai_helper.rb"

name 'openssl'

license 'OpenSSL'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'cacerts'

version = Gitlab::Version.new('openssl', 'OpenSSL_1_1_1k')

default_version version.print(false)
display_version version.print(false).delete_prefix('OpenSSL_').tr('_', '.')
vendor 'openssl'

source git: version.remote

build do
  env = with_standard_compiler_flags(with_embedded_path)

  configure_args = [
    "--prefix=#{install_dir}/embedded",
    'no-comp',
    'no-idea',
    'no-mdc2',
    'no-rc5',
    'no-ssl2',
    'no-ssl3',
    'no-zlib',
    'shared',
  ]

  prefix = if linux? && s390x?
             # With gcc > 4.3 on s390x there is an error building
             # with inline asm enabled
             './Configure linux64-s390x -DOPENSSL_NO_INLINE_ASM'
           elsif OhaiHelper.raspberry_pi?
             './Configure linux-generic32'
           else
             './config'
           end
  configure_cmd = "#{prefix} disable-gost"

  # Out of abundance of caution, we put the feature flags first and then
  # the crazy platform specific compiler flags at the end.
  configure_args << env['CFLAGS'] << env['LDFLAGS']

  configure_command = configure_args.unshift(configure_cmd).join(' ')

  command configure_command, env: env, in_msys_bash: true

  patch source: "openssl-1.1.1f-do-not-install-docs.patch", env: env

  make 'depend', env: env
  # make -j N on openssl is not reliable
  make env: env
  make 'install', env: env
end
