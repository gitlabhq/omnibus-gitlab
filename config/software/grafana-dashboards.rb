#
# Copyright:: Copyright (c) 2019 GitLab Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require "#{Omnibus::Config.project_root}/lib/gitlab/version"
version = Gitlab::Version.new('grafana-dashboards', '1.6.0')

name 'grafana-dashboards'
default_version version.print

dependency 'grafana'

license 'MIT'

skip_transitive_dependency_licensing true

source git: version.remote
relative_path 'grafana-dashboards'

build do
  # Copy dashboards.
  command "mkdir -p '#{install_dir}/embedded/service/grafana-dashboards'"
  sync 'omnibus/', "#{install_dir}/embedded/service/grafana-dashboards/"
end
