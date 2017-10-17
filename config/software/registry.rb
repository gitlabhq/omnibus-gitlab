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
version = Gitlab::Version.new('registry', 'dd544a82d93e8d39cec3d3d45117c3f486365589')

default_version version.print(false)

license 'Apache-2.0'
license_file "https://gitlab.com/gitlab-org/build/omnibus-mirror/distribution/raw/#{version.print(false)}/LICENSE"

source git: version.remote

relative_path 'src/github.com/docker/distribution'

build do
  env = {
    'GOPATH' => "#{Omnibus::Config.source_dir}/registry",
    'PREFIX' => "#{install_dir}/embedded",
    'DOCKER_BUILDTAGS' => 'include_gcs'
  }
  registry_source_dir = "#{Omnibus::Config.source_dir}/registry"
  cwd = "#{registry_source_dir}/src/github.com/docker/distribution"

  make "build", env: env, cwd: cwd
  make "binaries", env: env, cwd: cwd
end
