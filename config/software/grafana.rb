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
version = Gitlab::Version.new('grafana', '7.5.16')
default_version version.print(false)

license 'APACHE-2.0'
license_file 'LICENSE'
license_file 'NOTICE.md'

skip_transitive_dependency_licensing true

arch, sha = if OhaiHelper.raspberry_pi?
              %w[armv7 95039bd8c239b93819a381b37bcdf6c3d5515b189b748ea84bee49b692be38c7]
            elsif /aarch64/.match?(ohai['kernel']['machine'])
              %w[arm64 e5971fa967f5bf672e48127e9638ab4f2170bb6d0b23b7f6e64c70af65c3742b]
            else
              %w[amd64 78491e7c07a3f2d810a55256df526d66b7f3d6ee3628ae5ab3862b81838d7852]
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
