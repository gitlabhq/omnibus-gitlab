#
## Copyright:: Copyright (c) 2014 GitLab.com
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
require "#{Omnibus::Config.project_root}/lib/gitlab/prometheus_helper"

name 'prometheus'
version = Gitlab::Version.new('prometheus', '2.20.1')
default_version version.print

license 'APACHE-2.0'
license_file 'LICENSE'
license_file 'NOTICE'

skip_transitive_dependency_licensing true

source git: version.remote

relative_path 'src/github.com/prometheus/prometheus'

build do
  prometheus_source_dir = "#{Omnibus::Config.source_dir}/prometheus"
  cwd = "#{prometheus_source_dir}/#{relative_path}"
  env = {
    'GOPATH' => prometheus_source_dir,
    'GO111MODULE' => 'on',
  }

  prom_version = Prometheus::VersionFlags.new(version)

  make 'assets', env: env, cwd: cwd
  command "go build -mod=vendor -tags netgo,builtinassets -ldflags '#{prom_version.print_ldflags}' ./cmd/prometheus", env: env, cwd: cwd
  copy 'prometheus', "#{install_dir}/embedded/bin/prometheus"

  command "license_finder report --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=csv --save=license.csv"
  copy "license.csv", "#{install_dir}/licenses/prometheus.csv"
end
