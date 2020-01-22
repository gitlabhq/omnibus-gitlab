#
## Copyright:: Copyright (c) 2016 GitLab Inc.
## License:: Apache License, Version 2.0
##
## Licensed under the Apache License, Version 2.0 (the 'License');
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an 'AS IS' BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

require "#{Omnibus::Config.project_root}/lib/gitlab/version"

name 'postgres-exporter'
version = Gitlab::Version.new('postgres-exporter', '0.8.0')
default_version version.print

license 'Apache-2.0'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

source git: version.remote

relative_path 'src/github.com/wrouesnel/postgres_exporter'

build do
  env = {
    'GOPATH' => "#{Omnibus::Config.source_dir}/postgres-exporter",
  }

  ldflags = [
    "-X main.Version=#{version.print}",
  ].join(' ')

  command "go build -ldflags '#{ldflags}' ./cmd/postgres_exporter", env: env
  copy 'postgres_exporter', "#{install_dir}/embedded/bin/"

  command "license_finder report --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=csv --save=license.csv"
  copy "license.csv", "#{install_dir}/licenses/postgres-exporter.csv"
end
