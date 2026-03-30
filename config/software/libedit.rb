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

name 'libedit'
default_version '20150325-3.1'

license 'BSD-3-Clause'
license_file 'COPYING'

skip_transitive_dependency_licensing true

dependency 'ncurses'
dependency 'config_guess'
if Build::Check.use_ubt?
  ubt_version = default_version.tr('-', '_')
  source Build::UBT.source_args(name, "#{ubt_version}-2ubt", "cd8d493f8d4eb15ae10d66383a0a26a71ea95c311e0f584dd54388b23e801e39", OhaiHelper.arch)
  build(&Build::UBT.install)
else
  version('20150325-3.1') { source sha256: 'c88a5e4af83c5f40dda8455886ac98923a9c33125699742603a88a0253fcc8c5' }

  source url: "http://www.thrysoee.dk/editline/libedit-#{version}.tar.gz"

  if version == '20141030-3.1'
    # released tar file has name discrepency in folder name for this version
    relative_path 'libedit-20141029-3.1'
  else
    relative_path "libedit-#{version}"
  end

  build do
    env = with_standard_compiler_flags(with_embedded_path)

    update_config_guess

    command './configure' \
            " --prefix=#{install_dir}/embedded", env: env

    make "-j #{workers}", env: env
    make "-j #{workers} install", env: env
  end
end
