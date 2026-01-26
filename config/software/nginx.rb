#
# Copyright:: Copyright (c) 2012-2014 Chef Software, Inc.
# Copyright:: Copyright (c) 2014 GitLab Inc.
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

version = Gitlab::Version.new('nginx', 'release-1.29.0')
default_version version.print(false)
display_version version.print(false).delete_prefix('release-')

license 'BSD-2-Clause'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

if Build::Check.use_ubt?
  # TODO: We're using OhaiHelper to detect current platform, however since components are pre-compiled by UBT we *may* run ARM build on X86 nodes
  source Build::UBT.source_args(name, "#{display_version}-1ubt", "756713ceb2e739e495d18768a25c47f4c50d5382a153e24c4f30bd45e2d9330f", OhaiHelper.arch)
  build(&Build::UBT.install)
else
  source git: version.remote

  # From https://www.nginx.com/resources/admin-guide/installing-nginx-open-source/
  # Runtime dependencies
  dependency 'pcre2'
  dependency 'zlib-ng'
  dependency 'openssl' unless Build::Check.use_system_ssl?

  # Include the nginx-module-vts for metrics.
  dependency 'nginx-module-vts'

  dependency 'ngx_security_headers'

  build do
    cwd = "#{Omnibus::Config.source_dir}/nginx"

    nginx_module_dir = File.join(install_dir, "src", "nginx_modules")
    nginx_module_vts_dir = File.join(nginx_module_dir, "nginx-module-vts")
    ngx_security_headers_dir = File.join(nginx_module_dir, "ngx_security_headers")

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
             "--add-module=#{nginx_module_vts_dir}",
             "--add-module=#{ngx_security_headers_dir}",
             "--with-ld-opt=-L#{install_dir}/embedded/lib",
             "--with-cc-opt=\"-L#{install_dir}/embedded/lib -I#{install_dir}/embedded/include\""].join(' '), cwd: cwd
    command "make -j #{workers}", env: { 'LD_RUN_PATH' => "#{install_dir}/embedded/lib" }, cwd: cwd
    command 'make install', cwd: cwd
  end
end
