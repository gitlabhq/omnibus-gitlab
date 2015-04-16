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
name "mysql-client"
default_version "5.5.37"

dependency "openssl"
dependency "zlib"
dependency "ncurses"

source  :url => "http://dev.mysql.com/get/Downloads/MySQL-5.5/mysql-5.5.37.tar.gz",
        :md5 => "bf1d80c66d4822ec6036300399a33c03"

relative_path "mysql-#{version}"

env = with_standard_compiler_flags(with_embedded_path)
env.merge!(
  "CXXFLAGS" => "-L#{install_dir}/embedded/lib -I#{install_dir}/embedded/include",
  "CPPFLAGS" => "-L#{install_dir}/embedded/lib -I#{install_dir}/embedded/include",
)

# Force CentOS-5 to use gcc/g++ v4.4
if ohai['platform'] =~ /centos/ and ohai['platform_version'] =~ /^5/
    env.merge!( {
        "CC" => "gcc44",
        "CXX" => "g++44"
    })
end

build do

  command [
            "cmake",
            "-DCMAKE_SKIP_RPATH=YES",
            "-DCMAKE_INSTALL_PREFIX=#{install_dir}/embedded",
            "-DWITH_SSL=system",
            "-DOPENSSL_INCLUDE_DIR:PATH=#{install_dir}/embedded/include",
            "-DOPENSSL_LIBRARIES:FILEPATH=#{install_dir}/embedded/lib/libssl.so",
            "-DWITH_ZLIB=system",
            "-DZLIB_INCLUDE_DIR:PATH=#{install_dir}/embedded/include",
            "-DZLIB_LIBRARY:FILEPATH=#{install_dir}/embedded/lib/libz.so",
            "-DCRYPTO_LIBRARY:FILEPATH=#{install_dir}/embedded/lib/libcrypto.so",
            ".",
           ].join(" "), :env => env

  %w{libmysql client include}.each do |target|
    command "make -j #{workers} install", :env => env, :cwd => "#{project_dir}/#{target}"
  end
end
