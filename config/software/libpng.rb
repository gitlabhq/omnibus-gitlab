#
# Copyright:: Copyright (c) 2018 GitLab Inc.
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

name 'libpng'
version = Gitlab::Version.new('libpng', 'v1.6.50')

default_version version.print(false)

license 'Libpng'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'zlib-ng'

if Build::Check.use_ubt? && !Build::Check.use_system_ssl?
  # NOTE: We cannot use UBT binaries in FIPS builds
  # TODO: We're using OhaiHelper to detect current platform, however since components are pre-compiled by UBT we *may* run ARM build on X86 nodes
  # FIXME: version has drifted in Omnibus vs UBT builds
  source Build::UBT.source_args(name, "1.6.50", "99c482eeec1576fc2d27d4c04ab5ec583b28895347a74f5d9ed027565a770358", OhaiHelper.arch)
  build(&Build::UBT.install)
else
  source git: version.remote

  build do
    env = with_standard_compiler_flags(with_embedded_path)

    configure_command = [
      './configure',
      "--prefix=#{install_dir}/embedded",
      "--with-zlib=#{install_dir}/embedded"
    ]

    command configure_command.join(' '), env: env

    make "-j #{workers}", env: env
    make 'install', env: env
  end
end
