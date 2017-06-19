#
# Copyright:: Copyright (c) 2012-2014 Chef Software, Inc.
# Copyright:: Copyright (c) 2014 GitLab B.V.
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

name 'nginx'
default_version '1.12.0'

license 'BSD-2-Clause'
license_file 'LICENSE'

# From https://www.nginx.com/resources/admin-guide/installing-nginx-open-source/
# Runtime dependencies
dependency 'pcre'
dependency 'zlib'
dependency 'openssl'

version '1.12.0' do
  source sha256: 'b4222e26fdb620a8d3c3a3a8b955e08b713672e1bc5198d1e4f462308a795b30'
end

source url: "http://nginx.org/download/nginx-#{version}.tar.gz"

relative_path "nginx-#{version}"

build do
  command ['./configure',
           "--prefix=#{install_dir}/embedded",
           '--with-http_ssl_module',
           '--with-http_stub_status_module',
           '--with-http_gzip_static_module',
           '--with-http_v2_module',
           '--with-http_realip_module',
           '--with-ipv6',
           '--with-debug',
           "--with-ld-opt=-L#{install_dir}/embedded/lib",
           "--with-cc-opt=\"-L#{install_dir}/embedded/lib -I#{install_dir}/embedded/include\""].join(' ')
  command "make -j #{workers}", env: { 'LD_RUN_PATH' => "#{install_dir}/embedded/lib" }
  command 'make install'
end
