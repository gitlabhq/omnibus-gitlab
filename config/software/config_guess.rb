#
# Copyright 2015 Chef Software, Inc.
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

name 'config_guess'

# Locking version to a specific commit so that cache doesn't get invalidated unannounced
version = Gitlab::Version.new('config_guess', 'c9092d05347c925a26f6887980e185206e13f9d6')
default_version version.print(false)

# occasionally http protocol downloads get 500s, so we use git://
source git: version.remote

# http://savannah.gnu.org/projects/config
license 'GPL-3.0 (with exception)'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

relative_path "config_guess-#{version.print}"

build do
  patch source: 'add-license-file.patch'
  mkdir "#{install_dir}/embedded/lib/config_guess"

  copy "#{project_dir}/config.guess", "#{install_dir}/embedded/lib/config_guess/config.guess"
  copy "#{project_dir}/config.sub", "#{install_dir}/embedded/lib/config_guess/config.sub"
end
