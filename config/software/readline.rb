#
# Copyright:: Copyright (c) 2016 GitLab Inc.
# License:: Apache License, Version 2.0
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

name "readline"
default_version "6.2"

# http://buildroot-busybox.2317881.n4.nabble.com/PATCH-readline-link-directly-against-ncurses-td24410.html
# https://bugzilla.redhat.com/show_bug.cgi?id=499837
# http://lists.osgeo.org/pipermail/grass-user/2003-September/010290.html
# http://trac.sagemath.org/attachment/ticket/14405/readline-tinfo.diff
dependency "ncurses"

license "GPL-3.0"
license_file "COPYING"

source url: "ftp://ftp.gnu.org/gnu/readline/readline-#{version}.tar.gz",
       md5: "67948acb2ca081f23359d0256e9a271c"

relative_path "#{name}-#{version}"

build do
  env = {
      "CFLAGS" => "-I#{install_dir}/embedded/include",
      "LDFLAGS" => "-Wl,-rpath,#{install_dir}/embedded/lib -L#{install_dir}/embedded/lib"
  }

  configure_command = [
      "./configure",
      "--with-curses",
      "--prefix=#{install_dir}/embedded"
  ].join(" ")

  patch source: "readline-6.2-curses-link.patch", plevel: 1
  command configure_command, :env => env
  make " -j #{workers}", env: env
  make "install", env: env
end
