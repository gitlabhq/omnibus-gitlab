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

name 'chef-acme'
version = Gitlab::Version.new(name, '4.1.1')
default_version version.print(false)

license 'Apache-2.0'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

source git: version.remote

# Skip the gitlab-cookbook dependency if already loaded by the project. This improves build-ordering,
# due to how omnibus orders the components. Components that are dependencies of other components
# get moved in front of ones that are only defined in the project. Without this gate, gitlab-cookbooks
# ends up in front of components that change less frequently.
# Omnibus Build order: https://github.com/chef/omnibus/blob/c872e61c30d2b3f88ead03bd1254ff96d37059a3/lib/omnibus/library.rb#L64
dependency 'gitlab-cookbooks' unless project.dependencies.include?('gitlab-cookbooks')

dependency 'acme-client'
dependency 'compat_resource'

target_path = "#{install_dir}/embedded/cookbooks/acme"

build do
  sync "#{project_dir}/", target_path
end
