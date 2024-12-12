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

name 'gnupg'
default_version '2.2.41'

dependency 'bzip2'
dependency 'libassuan'
dependency 'libgcrypt' unless Build::Check.use_system_libgcrypt?
dependency 'libgpg-error'
dependency 'libksba'
dependency 'npth'
dependency 'zlib'

license 'LGPL-2.1'
license_file 'COPYING.LGPL3'

skip_transitive_dependency_licensing true

source url: "https://www.gnupg.org/ftp/gcrypt/gnupg/gnupg-#{version}.tar.bz2",
       sha256: '13f3291007a5e8546fcb7bc0c6610ce44aaa9b3995059d4f8145ba09fd5be3e1'

relative_path "gnupg-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  # For gnupg to build fine in Debian Wheezy and Centos ^
  env['LDFLAGS'] << " -lrt"

  prefix = "#{install_dir}/embedded"

  configure_command = [
    './configure',
    "--prefix=#{prefix}",
    '--disable-doc',
    '--without-readline',
    '--disable-sqlite',
    '--disable-gnutls',
    '--disable-dirmngr',
    "--with-libgpg-error-prefix=#{prefix}",
  ]

  # CentOS 6 doesn't have inotify, which will raise an error
  # IN_EXCL_UNLINK undeclared. Hence disabling it explicitly.
  configure_command << "ac_cv_func_inotify_init=no" if ohai['platform'] =~ /centos/ && ohai['platform_version'] =~ /^6/

  command configure_command.join(' '), env: env

  make "-j #{workers}", env: env
  make 'install', env: env
end
