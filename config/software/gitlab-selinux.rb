#
# Copyright:: Copyright (c) 2014 GitLab B.V.
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

name 'gitlab-selinux'

license 'Apache-2.0'
license_file File.expand_path('LICENSE', Omnibus::Config.project_root)

skip_transitive_dependency_licensing true

source path: File.expand_path('files/gitlab-selinux', Omnibus::Config.project_root)

build do
  policy_directory = File.expand_path('files/gitlab-selinux', Omnibus::Config.project_root)

  # Only type enforcement (te) is provided in the current policy
  Dir.glob("#{policy_directory}/*.te").each do |te_file|
    mod_file = te_file.sub(/\.te$/, ".mod")
    policy_file = te_file.sub(/\.te$/, ".pp")

    command "checkmodule -M -m -o #{mod_file} #{te_file}", cwd: policy_directory
    command "semodule_package -o #{policy_file} -m #{mod_file}", cwd: policy_directory
  end

  mkdir "#{install_dir}/embedded/selinux"
  copy "#{policy_directory}/*.pp", "#{install_dir}/embedded/selinux"
end
