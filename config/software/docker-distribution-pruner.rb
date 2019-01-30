#
# Copyright:: Copyright (c) 2019 GitLab B.V.
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
require "#{Omnibus::Config.project_root}/lib/gitlab/version"
version = Gitlab::Version.new('docker-distribution-pruner', '0.1.0')

name 'docker-distribution-pruner'
default_version version.print

license 'MIT'

skip_transitive_dependency_licensing true

source git: version.remote
relative_path 'src/gitlab.com/gitlab-org/docker-distribution-pruner'

build do
  env = { 'GOPATH' => "#{Omnibus::Config.source_dir}/docker-distribution-pruner" }

  command "go build -ldflags '-s -w' ./cmds/docker-distribution-pruner", env: env
  copy 'docker-distribution-pruner', "#{install_dir}/embedded/bin/"

  command "license_finder report --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=csv --save=license.csv"
  copy "license.csv", "#{install_dir}/licenses/docker-distribution-pruner.csv"
end
