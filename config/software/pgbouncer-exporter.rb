#
## Copyright:: Copyright (c) 2018 GitLab Inc.
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

name 'pgbouncer-exporter'
version = Gitlab::Version.new('pgbouncer-exporter', '0.11.0')
default_version version.print

license 'MIT'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

source git: version.remote

go_source = 'github.com/prometheus-community/pgbouncer_exporter'
relative_path "src/#{go_source}"

build do
  env = {
    'GOPATH' => "#{Omnibus::Config.source_dir}/pgbouncer-exporter",
    'GO111MODULE' => 'on',
    'GOTOOLCHAIN' => 'local',
  }
  prom_version = Prometheus::VersionFlags.new(version)

  command "go build -ldflags '#{prom_version.print_ldflags}'", env: env

  mkdir "#{install_dir}/embedded/bin"
  copy 'pgbouncer_exporter', "#{install_dir}/embedded/bin/"

  command "license_finder report --enabled-package-managers godep gomodules --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=json --columns name version licenses texts notice --save=license.json"
  copy "license.json", "#{install_dir}/licenses/pgbouncer-exporter.json"
end
