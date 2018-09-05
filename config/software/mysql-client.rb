#
# Copyright:: Copyright (c) 2013 Robby Dyer
# Copyright:: Copyright (c) 2014 GitLab.com
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
name 'mysql-client'
default_version '5.5.56'

license 'GPL-2.0'
license_file 'COPYING'

skip_transitive_dependency_licensing true

# Runtime dependecies
dependency 'openssl'
dependency 'zlib'
dependency 'ncurses'

source  url: "http://dev.mysql.com/get/Downloads/MySQL-5.5/mysql-#{version}.tar.gz",
        md5: '76a393f1aee0d57bf71e1a7414200233'

relative_path "mysql-#{version}"

env = with_standard_compiler_flags(with_embedded_path)
env['CXXFLAGS'] = "-L#{install_dir}/embedded/lib -I#{install_dir}/embedded/include"
env['CPPFLAGS'] = "-L#{install_dir}/embedded/lib -I#{install_dir}/embedded/include"

# Force CentOS-5 to use gcc/g++ v4.4
if ohai['platform'] =~ /centos/ && ohai['platform_version'] =~ /^5/
  env['CC'] = 'gcc44'
  env['CXX'] = 'g++44'
end

if ohai['platform'] =~ /ubuntu/ && ohai['platform_version'] =~ /^18\.04/
  env['CC'] = '/usr/bin/gcc-6'
  env['CXX'] = '/usr/bin/g++-6'
end

build do
  command [
    'cmake',
    '-DCMAKE_SKIP_RPATH=YES',
    "-DCMAKE_INSTALL_PREFIX=#{install_dir}/embedded",
    '-DWITH_SSL=system',
    '-DWITH_READLINE=1',
    "-DOPENSSL_INCLUDE_DIR:PATH=#{install_dir}/embedded/include",
    "-DOPENSSL_LIBRARIES:FILEPATH=#{install_dir}/embedded/lib/libssl.so",
    '-DWITH_ZLIB=system',
    "-DZLIB_INCLUDE_DIR:PATH=#{install_dir}/embedded/include",
    "-DZLIB_LIBRARY:FILEPATH=#{install_dir}/embedded/lib/libz.so",
    "-DCRYPTO_LIBRARY:FILEPATH=#{install_dir}/embedded/lib/libcrypto.so",
    '.'
  ].join(' '), env: env

  %w(libmysql client include).each do |target|
    command "make -j #{workers} install", env: env, cwd: "#{project_dir}/#{target}"
  end
end
