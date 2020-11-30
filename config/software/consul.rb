#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

name 'consul'
version = Gitlab::Version.new('consul', 'v1.6.6')
default_version version.print(false)

license 'MPL-2.0'
license_file 'LICENSE'

source git: version.remote

skip_transitive_dependency_licensing true

relative_path 'src/github.com/hashicorp/consul'

build do
  env = {}
  env['GOPATH'] = "#{Omnibus::Config.source_dir}/consul"
  env['PATH'] = "#{Gitlab::Util.get_env('PATH')}:#{env['GOPATH']}/bin"
  command 'make dev', env: env
  mkdir "#{install_dir}/embedded/bin"
  copy 'bin/consul', "#{install_dir}/embedded/bin/"

  command "license_finder report --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=csv --save=license.csv"
  copy "license.csv", "#{install_dir}/licenses/consul.csv"
end
