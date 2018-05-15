#
## Copyright:: Copyright (c) 2018 GitLab.com
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

name 'pgbouncer-exporter'
version = Gitlab::Version.new('pgbouncer-exporter', '0.2-gitlab')
default_version version.print

license 'MIT'
license_file 'LICENSE'

source git: version.remote

relative_path 'src/github.com/stanhu/pgbouncer_exporter'

build do
  cwd = "#{Omnibus::Config.source_dir}/pgbouncer-exporter"
  env = {
    'GOPATH' => cwd
  }
  command 'go get -d ...', env: env, cwd: cwd
  command 'make', env: env
  copy 'pgbouncer_exporter', "#{install_dir}/embedded/bin/"
end
