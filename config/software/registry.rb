#
## Copyright:: Copyright (c) 2016 GitLab Inc.
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

name 'registry'
version = Gitlab::Version.new('registry', 'v2.9.1-gitlab')

default_version version.print(false)

license 'Apache-2.0'
license_file 'LICENSE'

source git: version.remote

relative_path 'src/github.com/docker/distribution'

build do
  registry_source_dir = "#{Omnibus::Config.source_dir}/registry"
  cwd = "#{registry_source_dir}/#{relative_path}"
  env = {
    'GOPATH' => registry_source_dir,
    'BUILDTAGS' => 'include_gcs include_oss'
  }

  make "build", env: env, cwd: cwd
  make "binaries", env: env, cwd: cwd
  move "#{cwd}/bin/*", "#{install_dir}/embedded/bin", force: true

  command "license_finder report --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=csv --save=license.csv"
  copy "license.csv", "#{install_dir}/licenses/registry.csv"
end
