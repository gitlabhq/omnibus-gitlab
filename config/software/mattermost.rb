#
## Copyright:: Copyright (c) 2015 GitLab B.V.
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

name "mattermost"
default_version "63a17cf4f6c23ccd32a569194956425f22c761d6"

source :git => "https://github.com/mattermost/platform.git"

relative_path "golang/src/github.com/mattermost/platform"

dependency "rubygems"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  gopath = "#{Omnibus::Config.source_dir}/golang"
  command "mkdir -p #{gopath}"

  env.merge!(
    "GOPATH" => gopath
  )

  command "go get github.com/tools/godep", env: env
  command "#{gopath}/bin/godep restore", env: env

  gem "install compass -n #{install_dir}/embedded/bin --no-rdoc --no-ri -v 1.0.3", env: env

  command "go build mattermost.go", env: env, cwd: "#{Omnibus::Config.source_dir}/golang/src/github.com/mattermost/platform"
  move "#{Omnibus::Config.source_dir}/golang/src/github.com/mattermost/platform/mattermost", "#{install_dir}/embedded/bin/"
end
