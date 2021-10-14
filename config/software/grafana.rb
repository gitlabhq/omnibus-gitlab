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
require "#{Omnibus::Config.project_root}/lib/gitlab/ohai_helper.rb"

name 'grafana'
version = Gitlab::Version.new('grafana', '7.5.11')
default_version version.print(false)

license 'APACHE-2.0'
license_file 'LICENSE'
license_file 'NOTICE.md'

skip_transitive_dependency_licensing true

arch, sha = if OhaiHelper.raspberry_pi?
              %w[armv7 2a4e6da6b70e8d39c04b884d210036d2e55e05c7413abe7ba12b7a1d1064ecb0]
            elsif /aarch64/.match?(ohai['kernel']['machine'])
              %w[arm64 3b18082d1159014015d52e6fe706fd91d9862b659d5ff9ba1c1641072544702e]
            else
              %w[amd64 3244d0ced48d2de9726c9a3bd6d5f08c1b6a081d42665401e033fc4a31c57d5d]
            end

source url: "https://dl.grafana.com/oss/release/grafana-#{default_version}.linux-#{arch}.tar.gz",
       sha256: sha

relative_path "grafana-#{default_version}"

build do
  # Binaries.
  copy 'bin/grafana-server', "#{install_dir}/embedded/bin/grafana-server"
  copy 'bin/grafana-cli', "#{install_dir}/embedded/bin/grafana-cli"
  # Static assets.
  command "mkdir -p '#{install_dir}/embedded/service/grafana/public'"
  sync 'public/', "#{install_dir}/embedded/service/grafana/public/"
  # Default configuration.
  command "mkdir -p '#{install_dir}/embedded/service/grafana/conf'"
  copy 'conf/defaults.ini', "#{install_dir}/embedded/service/grafana/conf/defaults.ini"
end
