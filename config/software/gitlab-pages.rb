#
# Copyright:: Copyright (c) 2016 GitLab B.V.
# License:: Apache License, Version 2.0
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
version = Gitlab::Version.new('gitlab-pages')

name 'gitlab-pages'
default_version version.print

license 'MIT'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

source git: version.remote
relative_path 'src/gitlab.com/gitlab-org/gitlab-pages'

build do
  # This is required for GO15VENDOREXPERIMENT=1 to work properly,
  # since it requires the package to be in $GOPATH/src/package
  env = { 'GOPATH' => "#{Omnibus::Config.source_dir}/gitlab-pages" }

  make 'gitlab-pages', env: env
  move 'gitlab-pages', "#{install_dir}/embedded/bin/gitlab-pages"

  command "license_finder report --enabled-package-managers godep gomodules dep --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=json --columns name version licenses texts notice --save=license.json"
  copy "license.json", "#{install_dir}/licenses/gitlab-pages.json"
end
