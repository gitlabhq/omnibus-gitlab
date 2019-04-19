#
# Copyright 2018 GitLab
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

name 'go-crond'
version = Gitlab::Version.new('go-crond', '0.6.1')
default_version version.print(false)

license 'BSD-2-Clause'
license_file 'LICENSE'

source git: version.remote

relative_path 'src/github.com/webdevops/go-crond'

build do
  env = {
    'GOPATH' => "#{Omnibus::Config.source_dir}/go-crond",
  }

  # Install dep - maybe this should live in the builder definition?
  command 'go get github.com/golang/dep', env: env
  command 'go install github.com/golang/dep/cmd/dep', env: env

  # Install exact versions of the dependencies
  patch source: 'lock-dependencies.patch'
  command "../../../../bin/dep ensure", env: env

  command 'go build', env: env
  copy 'go-crond', "#{install_dir}/embedded/bin/"
end
