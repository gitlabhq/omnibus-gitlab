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

license 'Apache-2.0'
license_file 'LICENSE.txt'

skip_transitive_dependency_licensing true

dependency 'cacerts'

version = Gitlab::Version.new('openssl', "openssl-#{Gitlab::Util.get_env('OPENSSL_VERSION')}")

default_version version.print(false)
version_string = version.print(false).delete_prefix('openssl-')
display_version version_string

vendor 'openssl'

# UBT does not produce Arm64 binaries yet.
if Build::Check.use_ubt?
  # TODO: We're using OhaiHelper to detect current platform, however since components are pre-compiled by UBT we *may* run ARM build on X86 nodes
  ubt_version = "#{version_string}-1ubt"
  source Build::UBT.source_args(name, ubt_version, "1feaa222bd8f6dbe825615b301339c7b933ce75ce5641d9ec2fe41e7d98ca747", OhaiHelper.arch)
  build(&Build::UBT.install)
else
  source git: version.remote
  build do
    env = with_standard_compiler_flags(with_embedded_path)

    configure_args = [
      "--prefix=#{install_dir}/embedded",
      "--libdir=lib",
      'no-unit-test',
      'no-docs',
      'no-comp',
      'no-idea',
      'no-mdc2',
      'no-rc5',
      'no-ssl3',
      'no-zlib',
      'shared',
    ]

    prefix = if linux? && s390x?
               # With gcc > 4.3 on s390x there is an error building
               # with inline asm enabled
               './Configure linux64-s390x -DOPENSSL_NO_INLINE_ASM'
             elsif OhaiHelper.raspberry_pi?
               # 32-bit arm OSs require linking against libatomic
               './Configure linux-latomic'
             else
               './config'
             end
    configure_cmd = "#{prefix} disable-gost"

    # Out of abundance of caution, we put the feature flags first and then
    # the crazy platform specific compiler flags at the end.
    configure_args << env['CFLAGS'] << env['LDFLAGS']

    configure_command = configure_args.unshift(configure_cmd).join(' ')

    command configure_command, env: env, in_msys_bash: true

    make 'depend', env: env
    # make -j N on openssl is not reliable
    make env: env
    make 'install', env: env
  end
end
