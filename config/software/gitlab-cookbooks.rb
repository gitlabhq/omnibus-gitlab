#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2014 GitLab.com
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

name "gitlab-cookbooks"

license "Apache-2.0"
license_file "LICENSE"

source :path => File.expand_path("files/gitlab-cookbooks", Omnibus::Config.project_root)

build do
  # Copy in the Omnibus project's LICENSE, since this carries the same license as the source tree.
  copy File.join(Omnibus::Config.project_root, "LICENSE"),
       File.join(Omnibus::Config.source_dir, "#{name}/LICENSE")
  command "mkdir -p #{install_dir}/embedded/cookbooks"
  sync "./", "#{install_dir}/embedded/cookbooks/"

  # Create a package cookbook.
  command "mkdir -p #{install_dir}/embedded/cookbooks/package/attributes"
  erb :dest => "#{install_dir}/embedded/cookbooks/package/attributes/default.rb",
      :source => "cookbook_packages_default.erb",
      :mode => 0755,
      :vars => { :install_dir => project.install_dir }
end
