#
# Copyright:: Copyright (c) 2020 GitLab Inc.
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

name 'patroni'
default_version '1.6.4'

license 'MIT'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'python3'
dependency 'psycopg2'

build do
  env = with_standard_compiler_flags(with_embedded_path)

  patch source: "add-license-file.patch"

  # Version 1.0 of PrettyTable does not work with Patroni 1.6.4
  # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5701
  command "#{install_dir}/embedded/bin/pip3 install prettytable==0.7.2", env: env

  command "#{install_dir}/embedded/bin/pip3 install patroni[consul]==#{version}", env: env
end
