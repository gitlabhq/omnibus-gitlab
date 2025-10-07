#
## Copyright:: Copyright (c) 2014 GitLab Inc.
## License:: Apache License, Version 2.0
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

require "#{Omnibus::Config.project_root}/lib/gitlab/version"

name 'cosign'
version = Gitlab::Version.new('cosign', '2.5.3')
default_version version.print

license 'APACHE-2.0'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

source git: version.remote

relative_path 'src/github.com/cosign/cosign'

build do
  cosign_source_dir = "#{Omnibus::Config.source_dir}/cosign"
  cwd = "#{cosign_source_dir}/#{relative_path}"
  env = {
    'GOPATH' => cosign_source_dir,
    'GO111MODULE' => 'on',
    'CGO_ENABLED' => '1',
    'GOTOOLCHAIN' => 'local',
    'GOBIN' => "#{install_dir}/embedded/bin",
  }

  command %w[go install -a -trimpath -ldflags "-s -w" ./cmd/cosign], env: env, cwd: cwd

  command "license_finder report --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=json --columns name version licenses texts notice --save=license.json"
  copy "license.json", "#{install_dir}/licenses/cosign.json"
end
