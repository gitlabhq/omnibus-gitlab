#
# Copyright:: Chef Software, Inc.
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

name 'libyaml'
default_version '0.2.5'

license 'MIT'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'config_guess'

if Build::Check.use_ubt?
  # TODO: We're using OhaiHelper to detect current platform, however since components are pre-compiled by UBT we *may* run ARM build on X86 nodes
  source Build::UBT.source_args(name, "#{default_version}-1ubt", "f16bb66a43ed6624c36772fb1c858b1d84257b1a6d1e999101bccf6d74424851", OhaiHelper.arch)
  build(&Build::UBT.install)
else
  # versions_list: https://pyyaml.org/download/libyaml/ filter=*.tar.gz
  version('0.2.5') { source sha256: 'c642ae9b75fee120b2d96c712538bd2cf283228d2337df2cf2988e3c02678ef4' }

  source url: "https://pyyaml.org/download/libyaml/yaml-#{version}.tar.gz"

  relative_path "yaml-#{version}"

  build do
    env = with_standard_compiler_flags(with_embedded_path)

    update_config_guess(target: 'config')

    configure '--enable-shared', env: env

    make "-j #{workers}", env: env
    make "-j #{workers} install", env: env
  end
end
