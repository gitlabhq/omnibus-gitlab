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

name 'libxslt'
default_version '1.1.32'

license 'MIT'
license_file 'COPYING'

skip_transitive_dependency_licensing true

dependency 'libxml2'
dependency 'liblzma'
dependency 'config_guess'
dependency 'libtool' if solaris_10?
dependency 'patch' if solaris_10?

version '1.1.32' do
  source md5: '1fc72f98e98bf4443f1651165f3aa146'
end

source url: "ftp://xmlsoft.org/libxml2/libxslt-#{version}.tar.gz"

relative_path "libxslt-#{version}"

build do
  update_config_guess

  env = with_standard_compiler_flags(with_embedded_path)

  patch source: 'libxslt-solaris-configure.patch', env: env if solaris?

  # the libxslt configure script iterates directories specified in
  # --with-libxml-prefix looking for the libxml2 config script. That
  # iteration treats colons as a delimiter so we are using a cygwin
  # style path to accommodate
  configure_commands = [
    "--with-libxml-prefix=#{install_dir.sub('C:', '/C')}/embedded",
    '--without-python',
    '--without-crypto'
  ]

  configure(*configure_commands, env: env)

  if windows?
    # Apply a post configure patch to prevent dll base address clash
    patch source: 'libxslt-windows-relocate.patch', env: env if windows?
  end

  make "-j #{workers}", env: env
  make 'install', env: env
end

project.exclude 'embedded/lib/xsltConf.sh'
project.exclude 'embedded/bin/xslt-config'
