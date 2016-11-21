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

name 'redis-exporter'
default_version 'v0.10.6'

license 'MIT'
license_file 'LICENSE'

source git: 'https://github.com/oliver006/redis_exporter.git'

relative_path 'src/github.com/oliver006/redis_exporter'

build do
  env = {
    'GOPATH' => "#{Omnibus::Config.source_dir}/redis-exporter",
    'GO15VENDOREXPERIMENT' => '1' # Build machines have go 1.5.x, use vendor directory
  }
  command 'go install github.com/Masterminds/glide', env: env
  command '../../../../bin/glide install ', env: env
  command 'go build', env: env
  copy 'redis_exporter', "#{install_dir}/embedded/bin/"
end
