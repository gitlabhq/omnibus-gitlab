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

name 'compat_resource'
default_version 'v12.19.1'

license 'Apache-2.0'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

source git: 'https://github.com/chef-cookbooks/compat_resource.git'

target_path = "#{install_dir}/embedded/cookbooks/compat_resource"

build do
  sync "#{project_dir}/", target_path
end
