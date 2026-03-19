#
# Copyright 2013-2014 Chef Software, Inc.
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

name 'logrotate'
version = Gitlab::Version.new(name, '3.22.0')
default_version version.print(false)

license 'GPL-2.0'
license_file 'COPYING'

skip_transitive_dependency_licensing true

dependency 'popt'
if Build::Check.use_ubt?
  source Build::UBT.source_args(name, "#{default_version}-1ubt", "0652894f5061a93ac596db2ecd847a183b08f5e29e02c0c6939819287dc99119", OhaiHelper.arch)
  build(&Build::UBT.install)
else
  source git: version.remote

  build do
    env = with_standard_compiler_flags(with_embedded_path)

    command './autogen.sh', env: env
    command './configure' " --prefix=#{install_dir}/embedded --without-selinux", env: env
    make "-j #{workers}", env: env

    make 'install', env: env
  end
end
