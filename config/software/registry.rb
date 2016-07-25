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

name "registry"
default_version "v2.4.1"

license "Apache-2.0"
license_file "https://github.com/docker/distribution/blob/#{version}/LICENSE"

source :git => "https://github.com/docker/distribution.git"

relative_path "github.com/docker/distribution"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  env = { 'GOPATH' => "#{Omnibus::Config.base_dir}"}
  cwd = "#{Omnibus::Config.source_dir}/github.com/docker/distribution"

  command "go get github.com/tools/godep", env: env, cwd: cwd
  command "$GOPATH/bin/godep restore", env: env, cwd: cwd
  make "build PREFIX=#{install_dir}/embedded", env: env, cwd: cwd
  make "binaries PREFIX=#{install_dir}/embedded", env: env, cwd: cwd
end
