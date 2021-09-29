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

name 'ncurses'
default_version '5.9'

license 'MIT'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'config_guess'

version('5.9') { source md5: '8cb9c412e5f2d96bc6f459aa8c6282a1', url: 'http://ftp.gnu.org/gnu/ncurses/ncurses-5.9.tar.gz' }

relative_path "ncurses-#{version}"

########################################################################
#
# wide-character support:
# Ruby 1.9 optimistically builds against libncursesw for UTF-8
# support. In order to prevent Ruby from linking against a
# package-installed version of ncursesw, we build wide-character
# support into ncurses with the "--enable-widec" configure parameter.
# To support other applications and libraries that still try to link
# against libncurses, we also have to create non-wide libraries.
#
# The methods below are adapted from:
# http://www.linuxfromscratch.org/lfs/view/development/chapter06/ncurses.html
#
########################################################################

build do
  patch source: 'add-license-file.patch'
  env = with_standard_compiler_flags(with_embedded_path)
  env.delete('CPPFLAGS')

  if version == '5.9'
    # Patch to add support for GCC 5, doesn't break previous versions
    patch source: 'ncurses-5.9-gcc-5.patch', plevel: 1, env: env
  end

  update_config_guess

  configure_command = [
    './configure',
    "--prefix=#{install_dir}/embedded",
    '--enable-overwrite',
    '--with-shared',
    '--with-termlib',
    '--without-ada',
    '--without-cxx-binding',
    '--without-debug',
    '--without-manpages'
  ]

  command configure_command.join(' '), env: env

  make "-j #{workers}", env: env
  make "-j #{workers} install", env: env

  # Build non-wide-character libraries
  make 'distclean', env: env
  configure_command << '--enable-widec'

  command configure_command.join(' '), env: env
  make "-j #{workers}", env: env

  # Installing the non-wide libraries will also install the non-wide
  # binaries, which doesn't happen to be a problem since we don't
  # utilize the ncurses binaries in private-chef (or oss chef)
  make "-j #{workers} install", env: env
end

project.exclude "embedded/bin/ncurses5-config"
project.exclude "embedded/bin/ncursesw5-config"
