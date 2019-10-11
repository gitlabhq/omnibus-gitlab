#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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
version = Gitlab::Version.new('gitlab-elasticsearch-indexer')

name 'gitlab-elasticsearch-indexer'
default_version version.print

license 'MIT'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'libicu'

source git: version.remote

build do
  env = with_standard_compiler_flags(with_embedded_path)

  make "install PREFIX=#{install_dir}/embedded", env: env
  command "license_finder report --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=csv --save=license.csv"
  copy "license.csv", "#{install_dir}/licenses/gitlab-elasticsearch-indexer.csv"
end
