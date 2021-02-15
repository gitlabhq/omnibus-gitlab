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

name 'grafana'
version = Gitlab::Version.new('grafana', '7.4.2')
default_version version.print(false)

license 'APACHE-2.0'
license_file 'LICENSE'
license_file 'NOTICE.md'

skip_transitive_dependency_licensing true

arch, sha = if ohai['platform'] == 'debian' && /armv/.match?(ohai['kernel']['machine'])
              %w[armv7 1137322abdf543484d2ff39e01591a95542fac46381c0940647e30df2d7bfc82]
            elsif /aarch64/.match?(ohai['kernel']['machine'])
              %w[arm64 b1b8dc8e2c44f8ffc0128e1c2ce00aa60a4e0589b3b7616efc7a3e7e6e6be217]
            else
              %w[amd64 a653dbe83dc0b7e74c7ad94982484fa38c58e7249c32814380322b7e9f35eca9]
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
