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

version = Gitlab::Version.new('ncurses', '6315e1a380ecdb706d4f6518d2e8c7eb0db8fbe2')

default_version version.print(false)
display_version '6.4-20230225'

source git: version.remote

license 'MIT'
license_file 'COPYING'

skip_transitive_dependency_licensing true

dependency 'config_guess'

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
  env = with_standard_compiler_flags(with_embedded_path)
  env.delete('CPPFLAGS')

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

project.exclude "embedded/bin/ncurses6-config"
project.exclude "embedded/bin/ncursesw6-config"
