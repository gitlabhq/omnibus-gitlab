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

name 'rsync'

# This version is affected by CVE-2017-16548. However, rsync is not directly
# used by GitLab codebase. It is provided to be used in two manual tasks -
# backup/restore rake task and wrapper script for moving repositories to a new
# location. Since the scope of this vulnerability is limited, we decided to
# wait for next release of rsync rather than patching it. For details, check
# https://gitlab.com/gitlab-org/omnibus-gitlab/issues/3391
default_version '3.1.3'

license 'GPL v3'
license_file 'COPYING'

skip_transitive_dependency_licensing true

dependency 'popt'

version '3.1.3' do
  source sha256: '55cc554efec5fdaad70de921cd5a5eeb6c29a95524c715f3bbf849235b0800c0'
end

source url: "https://rsync.samba.org/ftp/rsync/src/rsync-#{version}.tar.gz"

relative_path "rsync-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  command './configure' \
          " --prefix=#{install_dir}/embedded" \
          ' --disable-iconv', env: env

  make "-j #{workers}", env: env
  make 'install', env: env
end
