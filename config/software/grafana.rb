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
version = Gitlab::Version.new('grafana', '7.3.6')
default_version version.print(false)

license 'APACHE-2.0'
license_file 'LICENSE'
license_file 'NOTICE.md'

skip_transitive_dependency_licensing true

arch, sha = if ohai['platform'] == 'debian' && /armv/.match?(ohai['kernel']['machine'])
              %w[armv7 53e3fd89db3610286077e98169e61f29c364521c6852e62ccb16bb95208b4ad3]
            elsif /aarch64/.match?(ohai['kernel']['machine'])
              %w[arm64 08311678754c1554d8c9a4824e30fdf9886f8d7043e4b0719212df61e7e4287c]
            else
              %w[amd64 2eb4e5a2aa3990a5299fd40b41a1fedf8fad53a8dfb144b60d804d9cc6b384ba]
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
