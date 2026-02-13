#
# Copyright:: Copyright (c) 2013-2014 Chef Software, Inc.
# Copyright:: Copyright (c) 2016-2021 GitLab Inc.
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

name 'python3'
# If bumping from 3.12.x to something higher, be sure to update the following files with the new path:
# files/gitlab-config-template/gitlab.rb.template
# files/gitlab-cookbooks/gitaly/recipes/enable.rb
# files/gitlab-cookbooks/gitlab/attributes/default.rb
# spec/chef/cookbooks/gitaly/recipes/gitaly_spec.rb
# spec/chef/cookbooks/gitlab/recipes/gitlab-rails_spec.rb
default_version '3.12.12'

dependency 'libedit'
dependency 'ncurses'
dependency 'zlib-ng'
dependency 'openssl' unless Build::Check.use_system_ssl?
dependency 'bzip2'
dependency 'libffi'
dependency 'liblzma'
dependency 'libyaml'

license 'Python-2.0'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

source url: "https://www.python.org/ftp/python/#{version}/Python-#{version}.tgz",
       sha256: '487c908ddf4097a1b9ba859f25fe46d22ccaabfb335880faac305ac62bffb79b'

relative_path "Python-#{version}"

LIB_PATH = %W(#{install_dir}/embedded/lib #{install_dir}/embedded/lib64 #{install_dir}/lib #{install_dir}/lib64 #{install_dir}/libexec).freeze

env = {
  'CFLAGS' => "-I#{install_dir}/embedded/include -O3 -g -pipe",
  'LDFLAGS' => "-Wl,-rpath,#{LIB_PATH.join(',-rpath,')} -L#{LIB_PATH.join(' -L')} -I#{install_dir}/embedded/include",
  'PKG_CONFIG_PATH' => "#{install_dir}/embedded/lib/pkgconfig"
}

build do
  # Patch to avoid building nis module in Debian 11. If nis is built, it gets
  # linked to system `nsl` and `tirpc` libraries and thus fails omnibus
  # healthcheck in Debian 11 and Ubuntu 22.04.
  patch source: 'skip-nis-build.patch' if
    (ohai['platform_family'] =~ /^debian/ && ohai['platform_version'] =~ /^1[123]/) ||
      (ohai['platform'] =~ /^ubuntu/ && ohai['platform_version'] =~ /^22/)

  openssl_dir = Build::Check.use_system_ssl? ? "/usr" : "#{install_dir}/embedded"
  command ['./configure',
           "--prefix=#{install_dir}/embedded",
           '--enable-shared',
           '--with-readline=editline',
           "--with-openssl=#{openssl_dir}",
           '--with-dbmliborder='].join(' '), env: env
  make env: env
  make 'install', env: env

  delete("#{install_dir}/embedded/lib/python3.12/lib-dynload/dbm.*")
  delete("#{install_dir}/embedded/lib/python3.12/lib-dynload/_sqlite3.*")
  delete("#{install_dir}/embedded/lib/python3.12/test")
  command "find #{install_dir}/embedded/lib/python3.12 -name '__pycache__' -type d -print -exec rm -r {} +"
end

project.exclude "embedded/bin/python3*-config"
