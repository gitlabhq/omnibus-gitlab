#
# Copyright:: Copyright (c) 2022 GitLab Inc.
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

name 'libarchive'
default_version '3.7.5'

license 'BSD-2-Clause'
license_file 'COPYING'

skip_transitive_dependency_licensing true

source url: "https://www.libarchive.org/downloads/libarchive-#{version}.tar.gz",
       sha256: '37556113fe44d77a7988f1ef88bf86ab68f53d11e85066ffd3c70157cc5110f1'

relative_path "libarchive-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # If libarchive is present in system library locations and not bundled with
  # omnibus-gitlab package, then Chef will incorrectly attempt to use it, and
  # can potentially fail as seen from
  # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7741. Hence, we need
  # to bundle libarchive in the package. But, we don't need support for any of
  # the possible extensions as we are not using it's functionality at all. So,
  # when it comes to these extensions, YAGNI. Hence disabling all that can be
  # disabled.
  disable_flags = [
    '--without-zlib',
    '--without-bz2lib',
    '--without-libb2',
    '--without-iconv',
    '--without-lz4',
    '--without-zstd',
    '--without-lzma',
    '--without-cng',
    '--without-openssl',
    '--without-xml2',
    '--without-expat',
    '--without-lzo2',
    '--without-mbedtls',
    '--without-nettle',
    '--disable-posix-regex-lib',
    '--disable-xattr',
    '--disable-acl',
    '--disable-bsdtar',
    '--disable-bsdcat',
    '--disable-bsdcpio',
  ]

  configure disable_flags.join(' '), env: env

  make "-j #{workers}", env: env
  make 'install', env: env
end
