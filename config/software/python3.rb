#
# Copyright:: Copyright (c) 2013-2014 Chef Software, Inc.
# Copyright:: Copyright (c) 2016 GitLab B.V.
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

name "python3"
default_version "3.4.5"

dependency "readline"
dependency "ncurses"
dependency "zlib"
dependency "openssl"
dependency "bzip2"

license "Python-2.0"
license_file "LICENSE"

source :url => "http://python.org/ftp/python/#{version}/Python-#{version}.tgz",
       :md5 => '5f2ef90b1adef35a64df14d4bb7af733'

relative_path "Python-#{version}"

LIB_PATH = %W(#{install_dir}/embedded/lib #{install_dir}/embedded/lib64 #{install_dir}/embedded/libexec #{install_dir}/lib #{install_dir}/lib64 #{install_dir}/libexec)

env = {
  "CFLAGS" => "-I#{install_dir}/embedded/include -O3 -g -pipe",
  "LDFLAGS" => "-Wl,-rpath,#{LIB_PATH.join(',-rpath,')} -L#{LIB_PATH.join(' -L')} -I#{install_dir}/embedded/include"
}

build do
  command ["./configure",
           "--prefix=#{install_dir}/embedded",
           "--enable-shared",
           "--with-dbmliborder="].join(" "), env: env
  make env: env
  make "install", env: env

  delete("#{install_dir}/embedded/lib/python3.4/lib-dynload/dbm.*")
  delete("#{install_dir}/embedded/lib/python3.4/lib-dynload/_sqlite3.*")
end
