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

version = Gitlab::Version.new('nginx', 'release-1.20.1')
default_version version.print(false)
display_version version.print(false).delete_prefix('release-')

license 'BSD-2-Clause'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

source git: version.remote

# From https://www.nginx.com/resources/admin-guide/installing-nginx-open-source/
# Runtime dependencies
dependency 'pcre'
dependency 'zlib'
dependency 'openssl' unless Build::Check.use_system_ssl?

# Include the nginx-module-vts for metrics.
dependency 'nginx-module-vts'

dependency 'ngx_security_headers'

build do
  cwd = "#{Omnibus::Config.source_dir}/nginx"
  command ['./auto/configure',
           "--prefix=#{install_dir}/embedded",
           '--with-http_ssl_module',
           '--with-http_stub_status_module',
           '--with-http_gzip_static_module',
           '--with-http_v2_module',
           '--with-http_realip_module',
           '--with-http_sub_module',
           '--with-ipv6',
           '--with-debug',
           "--add-module=#{Omnibus::Config.source_dir}/nginx-module-vts",
           "--add-module=#{Omnibus::Config.source_dir}/ngx_security_headers",
           "--with-ld-opt=-L#{install_dir}/embedded/lib",
           "--with-cc-opt=\"-L#{install_dir}/embedded/lib -I#{install_dir}/embedded/include\""].join(' '), cwd: cwd
  command "make -j #{workers}", env: { 'LD_RUN_PATH' => "#{install_dir}/embedded/lib" }, cwd: cwd
  command 'make install', cwd: cwd
end
