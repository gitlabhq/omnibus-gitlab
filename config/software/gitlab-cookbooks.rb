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

name 'gitlab-cookbooks'

license 'Apache-2.0'
license_file File.expand_path('LICENSE', Omnibus::Config.project_root)

skip_transitive_dependency_licensing true

EE = system("#{Omnibus::Config.project_root}/support/is_gitlab_ee.sh")

source path: File.expand_path('files/gitlab-cookbooks', Omnibus::Config.project_root)

build do
  cookbook_name = 'gitlab'

  command "mkdir -p #{install_dir}/embedded/cookbooks"
  sync './', "#{install_dir}/embedded/cookbooks/"

  solo_recipes = %w(dna postgresql-bin postgresql-config)

  # If EE package, use a different master cookbook
  if EE
    cookbook_name = 'gitlab-ee'
    solo_recipes << 'geo-postgresql-config'
    solo_recipes << 'patroni-config'
  else
    delete "#{install_dir}/embedded/cookbooks/gitlab-ee"
  end

  solo_recipes.each do |config|
    erb dest: "#{install_dir}/embedded/cookbooks/#{config}.json",
        source: "#{config}.json.erb",
        mode: 0644,
        vars: { master_cookbook: cookbook_name }
  end
end
