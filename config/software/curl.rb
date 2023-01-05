#
# Copyright 2012-2014 Chef Software, Inc.
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

name 'curl'

version = Gitlab::Version.new('curl', 'curl-7_87_0')

default_version version.print(false)
display_version version.print(false).delete_prefix('curl-').tr('_', '.')

# Runtime dependency
dependency 'zlib'
dependency 'openssl' unless Build::Check.use_system_ssl?
dependency 'libtool'

vendor 'haxx'
license 'MIT'
license_file 'COPYING'

skip_transitive_dependency_licensing true

source git: version.remote

build do
  env = with_standard_compiler_flags(with_embedded_path)
  env['ACLOCAL_PATH'] = "#{install_dir}/embedded/share/aclocal"

  delete "#{project_dir}/src/tool_hugehelp.c"

  configure_command = [
    './configure',
    "--prefix=#{install_dir}/embedded",
    "--disable-option-checking",
    '--disable-manual',
    '--disable-debug',
    '--enable-optimize',
    '--disable-ldap',
    '--disable-ldaps',
    '--disable-rtsp',
    '--enable-proxy',
    "--disable-pop3",
    "--disable-imap",
    "--disable-smtp",
    "--disable-gopher",
    '--disable-dependency-tracking',
    '--enable-ipv6',
    "--without-libidn2",
    '--without-librtmp',
    "--without-zsh-functions-dir",
    "--without-fish-functions-dir",
    "--disable-mqtt",
    '--without-libssh2',
    '--without-nghttp2',
    "--with-zlib=#{install_dir}/embedded",
    "--without-ca-path",
    "--without-ca-bundle",
    "--with-ca-fallback"
  ]

  openssl_library_path = "=#{install_dir}/embedded" unless Build::Check.use_system_ssl?
  configure_command << "--with-openssl#{openssl_library_path}"

  command "autoreconf -fi", env: env
  command configure_command.join(' '), env: env

  make "-j #{workers}", env: env
  make 'install', env: env
end

project.exclude 'embedded/bin/curl-config'
