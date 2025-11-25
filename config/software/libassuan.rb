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

name 'libassuan'
default_version '2.5.5'

license 'LGPL-2.1'
license_file 'COPYING.LIB'

skip_transitive_dependency_licensing true

dependency 'libgpg-error'

if Build::Check.use_ubt?
  # TODO: We're using OhaiHelper to detect current platform, however since components are pre-compiled by UBT we *may* run ARM build on X86 nodes
  source Build::UBT.source_args(name, default_version, "749d240de12345d8363916c847f4403efc32c960ab953667763820a7d35e1c91", OhaiHelper.arch)
  build(&Build::UBT.install)
else
  source url: "https://www.gnupg.org/ftp/gcrypt/libassuan/libassuan-#{version}.tar.bz2",
         sha256: '8e8c2fcc982f9ca67dcbb1d95e2dc746b1739a4668bc20b3a3c5be632edb34e4'

  relative_path "libassuan-#{version}"

  build do
    env = with_standard_compiler_flags(with_embedded_path)
    prefix = "#{install_dir}/embedded"

    configure_command = [
      './configure',
      "--prefix=#{prefix}",
      '--disable-doc',
      "--with-libgpg-error-prefix=#{prefix}",
    ]

    command configure_command.join(' '), env: env

    make "-j #{workers}", env: env
    make 'install', env: env
  end
end

project.exclude "embedded/bin/libassuan-config"
