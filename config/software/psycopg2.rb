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

name 'psycopg2'
version = Gitlab::Version.new('psycopg2', '2_8_4')
default_version version.print(false)

license 'LGPL'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

source git: version.remote

dependency 'python3'
dependency 'postgresql_new'

pg_major_version = '12'

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # Prepend PostgreSQL's bin directory to the PATH, so that setup.py can find pg_config and build against it
  env['PATH'] = "#{install_dir}/embedded/postgresql/#{pg_major_version}/bin:#{env['PATH']}"

  command "#{install_dir}/embedded/bin/python3 setup.py build_ext", env: env
  command "#{install_dir}/embedded/bin/python3 setup.py install", env: env
end
