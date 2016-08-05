#
# Copyright:: Copyright (c) 2016 GitLab Inc
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

name "gitlab-gem-licenses"

combined_licenses_file = "#{install_dir}/embedded/service/gem/gitlab-gem-licenses"
gems_directory = "#{install_dir}/embedded/service/gem/ruby/2.1.0/gems/"

license_file combined_licenses_file

build do
  erb dest: "#{install_dir}/embedded/bin/gitlab-gem-license-generator",
    source: "gem_license_generator.erb",
    mode: 0755,
    vars: {install_dir: install_dir, license_file: combined_licenses_file, gems_directory: gems_directory}

  command "#{install_dir}/embedded/bin/ruby #{install_dir}/embedded/bin/gitlab-gem-license-generator"
  delete "#{install_dir}/embedded/bin/gitlab-gem-license-generator"
end
