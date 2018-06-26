#
# Copyright:: Copyright (c) 2017 GitLab Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "#{Omnibus::Config.project_root}/lib/gitlab/version"
require "#{Omnibus::Config.project_root}/lib/gitlab/prometheus_helper"

name 'node-exporter'
version = Gitlab::Version.new('node-exporter', '0.16.0')
default_version version.print

license 'APACHE-2.0'
license_file 'LICENSE'

source git: version.remote

relative_path 'src/github.com/prometheus/node_exporter'

build do
  env = {
    'GOPATH' => "#{Omnibus::Config.source_dir}/node-exporter",
    'CGO_ENABLED' => '0' # Details: https://github.com/prometheus/node_exporter/issues/870
  }
  exporter_source_dir = "#{Omnibus::Config.source_dir}/prometheus"
  cwd = "#{exporter_source_dir}/src/github.com/prometheus/node_exporter"

  prom_version = Prometheus::VersionFlags.new('node_exporter', version)

  command "go build -ldflags '#{prom_version.ldflags}'", env: env, cwd: cwd
  copy 'node_exporter', "#{install_dir}/embedded/bin/"
end
