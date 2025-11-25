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

name 'libgpg-error'
default_version '1.56'

license 'LGPL-2.1'
license_file 'COPYING.LIB'

skip_transitive_dependency_licensing true

if Build::Check.use_ubt?
  # TODO: We're using OhaiHelper to detect current platform, however since components are pre-compiled by UBT we *may* run ARM build on X86 nodes
  # FIXME: UBT build versions were behind the current changes in Omnibus
  source Build::UBT.source_args(name, '1.46', "4d4537005b70b0d10ac85e0eca12caf778c85899c20618d887bfc152469d024e", OhaiHelper.arch)
  build(&Build::UBT.install)
else
  source url: "https://www.gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-#{version}.tar.bz2",
         sha256: '82c3d2deb4ad96ad3925d6f9f124fe7205716055ab50e291116ef27975d169c0'

  relative_path "libgpg-error-#{version}"

  build do
    env = with_standard_compiler_flags(with_embedded_path)

    # gpg-error-config has been deprecated in favor of gpgrt-config
    # (https://dev.gnupg.org/T5683), but libassuan and gnupg currently
    # still use gpg-error-config if it is present. Older systems, such as
    # Amazon Linux 2, have a version that is too old, so we need to ensure
    # a recent version of gpg-error-config is installed.
    command './configure ' \
      "--prefix=#{install_dir}/embedded --enable-install-gpg-error-config --disable-doc", env: env

    make "-j #{workers}", env: env
    make 'install', env: env
  end
end

project.exclude 'embedded/bin/gpg-error-config'
