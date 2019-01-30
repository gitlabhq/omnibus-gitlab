#
## Copyright:: Copyright (c) 2018 GitLab, Inc.
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

name 'prometheus-2'
version = Gitlab::Version.new('prometheus', '2.6.1')
default_version version.print

license 'APACHE-2.0'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

source git: version.remote

dependency 'prometheus-storage-migrator'

go_source = 'github.com/prometheus/prometheus'
relative_path "src/#{go_source}"

build do
  env = {
    'GOPATH' => "#{Omnibus::Config.source_dir}/prometheus-2",
  }
  exporter_source_dir = "#{Omnibus::Config.source_dir}/prometheus-2"
  cwd = "#{exporter_source_dir}/src/#{go_source}"

  prom_version = Prometheus::VersionFlags.new(go_source, version)

  command "go build -ldflags '#{prom_version.print_ldflags}' ./cmd/prometheus", env: env, cwd: cwd
  copy 'prometheus', "#{install_dir}/embedded/bin/prometheus2"

  command "license_finder report --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=csv --save=license.csv"
  copy "license.csv", "#{install_dir}/licenses/prometheus-2.csv"
end
