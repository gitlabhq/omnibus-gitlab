#
# Copyright 2012-2014 Chef Software, Inc.
# Copyright 2017-2026 GitLab Inc.
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
name 'fast-stats'

version = Gitlab::Version.new('fast-stats', 'v0.8.5')
default_version version.print(false)

license 'MIT'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'gitlabsos'

source git: version.remote

build do
  cwd = "#{Omnibus::Config.source_dir}/fast-stats"
  dest_dir = "#{install_dir}/embedded/service/fast-stats/bin"
  mkdir dest_dir

  # Disable the plot features since this requires libraries that may not
  # supported on all our platforms. On Ubuntu the plot command needs
  # libfreetype6-dev and libfontconfig1-dev.
  command %w[cargo build --release --no-default-features], cwd: cwd

  move 'target/release/fast-stats', dest_dir

  # Symlink the fast-stats binary for "gitlabsos --include-stats"
  gitlabsos_bindir = "#{install_dir}/embedded/service/gitlabsos/bin"
  mkdir gitlabsos_bindir
  command %W[ln -sf #{dest_dir}/fast-stats #{gitlabsos_bindir}/fast-stats]
  command %W[ln -sf #{dest_dir}/fast-stats #{install_dir}/embedded/bin/fast-stats]
end
