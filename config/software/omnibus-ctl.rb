#
# Copyright 2012-2015 Chef Software, Inc.
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

name 'omnibus-ctl'
# Commit SHA of v0.6.0 is used because the tag is not pushed to the upstream
# repo.  Change it to v0.6.0 when that happens.
version = Gitlab::Version.new('omnibus-ctl', '1b96ac486636cac987e5b464810bb3ff673a93fe')
default_version version.print(false)

license 'Apache-2.0'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'ruby'
dependency 'rubygems'
dependency 'bundler'

source git: version.remote

relative_path 'omnibus-ctl'

build do
  env = with_standard_compiler_flags(with_embedded_path)
  patch source: 'skip-license-acceptance.patch'

  # Remove existing built gems in case they exist in the current dir
  delete 'omnibus-ctl-*.gem'

  gem 'build omnibus-ctl.gemspec', env: env
  gem 'install omnibus-ctl-*.gem --no-document', env: env

  touch "#{install_dir}/embedded/service/omnibus-ctl/.gitkeep"
end
