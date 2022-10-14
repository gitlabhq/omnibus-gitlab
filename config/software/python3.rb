#
# Copyright:: Copyright (c) 2013-2014 Chef Software, Inc.
# Copyright:: Copyright (c) 2016-2021 GitLab B.V.
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
# If bumping from 3.10.x to something higher, be sure to update the following files with the new path:
# files/gitlab-config-template/gitlab.rb.template
# files/gitlab-cookbooks/gitaly/recipes/enable.rb
# files/gitlab-cookbooks/gitlab/attributes/default.rb
# spec/chef/recipes/gitaly_spec.rb
# spec/chef/recipes/gitlab-rails_spec.rb
default_version '3.10.7'

dependency 'libedit'
dependency 'ncurses'
dependency 'zlib'
dependency 'openssl' unless Build::Check.use_system_ssl?
dependency 'bzip2'
dependency 'libffi'
dependency 'liblzma'
dependency 'libyaml'

license 'Python-2.0'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

source url: "https://www.python.org/ftp/python/#{version}/Python-#{version}.tgz",
       sha256: '1b2e4e2df697c52d36731666979e648beeda5941d0f95740aafbf4163e5cc126'

relative_path "Python-#{version}"

LIB_PATH = %W(#{install_dir}/embedded/lib #{install_dir}/embedded/lib64 #{install_dir}/lib #{install_dir}/lib64 #{install_dir}/libexec).freeze

env = {
  'CFLAGS' => "-I#{install_dir}/embedded/include -O3 -g -pipe",
  'LDFLAGS' => "-Wl,-rpath,#{LIB_PATH.join(',-rpath,')} -L#{LIB_PATH.join(' -L')} -I#{install_dir}/embedded/include"
}

build do
  # Patch to avoid building nis module in Debian 11. If nis is built, it gets
  # linked to system `nsl` and `tirpc` libraries and thus fails omnibus
  # healthcheck in Debian 11 and Ubuntu 22.04.
  patch source: 'skip-nis-build.patch' if
    (ohai['platform_family'] =~ /^debian/ && ohai['platform_version'] =~ /^11/) ||
      (ohai['platform'] =~ /^ubuntu/ && ohai['platform_version'] =~ /^22/)

  command ['./configure',
           "--prefix=#{install_dir}/embedded",
           '--enable-shared',
           '--with-readline=editline',
           '--with-dbmliborder='].join(' '), env: env
  make env: env
  make 'install', env: env

  delete("#{install_dir}/embedded/lib/python3.10/lib-dynload/dbm.*")
  delete("#{install_dir}/embedded/lib/python3.10/lib-dynload/_sqlite3.*")
  delete("#{install_dir}/embedded/lib/python3.10/test")
  command "find #{install_dir}/embedded/lib/python3.10 -name '__pycache__' -type d -print -exec rm -r {} +"
end

project.exclude "embedded/bin/python3*-config"
