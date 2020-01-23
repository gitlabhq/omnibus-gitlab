#
## Copyright:: Copyright (c) 2014 GitLab.com
## License:: Apache License, Version 2.0
##
## Licensed under the Apache License, Version 2.0 (the 'License');
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an 'AS IS' BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

require "#{Omnibus::Config.project_root}/lib/gitlab/version"
require 'time'

name 'redis-exporter'
version = Gitlab::Version.new('redis-exporter', '1.3.5')
default_version version.print

license 'MIT'
license_file 'LICENSE'

source git: version.remote

relative_path 'src/github.com/oliver006/redis_exporter'

build do
  env = {
    'GOPATH' => "#{Omnibus::Config.source_dir}/redis-exporter",
    'GO111MODULE' => 'on',
  }

  ldflags = [
    "-X main.BuildVersion=#{version.print(false)}",
    "-X main.BuildDate=''",
    "-X main.BuildCommitSha=''",
  ].join(' ')

  command "go build -mod=vendor -ldflags '#{ldflags}'", env: env
  copy 'redis_exporter', "#{install_dir}/embedded/bin/"

  command "license_finder report --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=csv --save=license.csv"
  copy "license.csv", "#{install_dir}/licenses/redis-exporter.csv"
end
