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
default_version 'v0.9.0'

license 'MPL-2.0'
license_file 'LICENSE'

version '0.9.0' do
  source sha256: '4e3db525b58ba9ed8d3f0a09047d4935180748f44be2a48342414bfcff3c69a4'
end

source git: 'https://github.com/hashicorp/consul.git'

skip_transitive_dependency_licensing true

relative_path 'src/github.com/hashicorp/consul'

build do
  env = {}
  env['GOPATH'] = "#{Omnibus::Config.source_dir}/consul"
  env['PATH'] = "#{ENV['PATH']}:#{env['GOPATH']}/bin"
  command 'make dev', env: env
  copy 'bin/consul', "#{install_dir}/embedded/bin/"
end
