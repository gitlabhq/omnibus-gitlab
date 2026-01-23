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
name 'gitlabsos'

version = Gitlab::Version.new('gitlabsos', '3064095d5ad3c00c3a1d08aca3264f361256fbcb')
default_version version.print(false)

license 'MIT'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'ruby'

source git: version.remote

build do
  cwd = "#{Omnibus::Config.source_dir}/gitlabsos"
  dest_dir = "#{install_dir}/embedded/service/gitlabsos"

  command %w[git submodule init], cwd: cwd
  command %w[git submodule update], cwd: cwd

  mkdir dest_dir
  sync './', "#{dest_dir}/", exclude: %w(
    .git*
    .rubocop*
    CODEOWNERS
    bin
    Gemfile
    Gemfile.lock
    sanitizer/.git*
    sanitizer/CODEOWNERS
    sanitizer/lefthook.yml
    sanitizer/test_*
  )

  # Rename the file so that we can symlink it easily in /usr/bin.
  move "#{dest_dir}/gitlabsos.rb", "#{dest_dir}/gitlabsos"
end
