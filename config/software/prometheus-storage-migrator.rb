
## Copyright:: Copyright (c) 2018 GitLab, Inc.
## License:: Apache License, Version 2.0
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

require "#{Omnibus::Config.project_root}/lib/gitlab/version"

name 'prometheus-storage-migrator'
version = Gitlab::Version.new('prometheus-storage-migrator', '0.2.0')
default_version version.print

license 'APACHE-2.0'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

source git: version.remote

go_source = 'gitlab.com/gitlab-org/prometheus-storage-migrator'
relative_path "src/#{go_source}"

build do
  env = {
    'GOPATH' => "#{Omnibus::Config.source_dir}/prometheus-storage-migrator",
  }
  source_dir = "#{Omnibus::Config.source_dir}/prometheus-storage-migrator"
  cwd = "#{source_dir}/src/gitlab.com/gitlab-org/prometheus-storage-migrator"

  command "go build", env: env, cwd: cwd
  copy 'prometheus-storage-migrator', "#{install_dir}/embedded/bin/"

  command "license_finder report --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=csv --save=license.csv"
  copy "license.csv", "#{install_dir}/licenses/prometheus-storage-migrator.csv"
end
