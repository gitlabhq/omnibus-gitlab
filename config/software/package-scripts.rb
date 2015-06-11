#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2015 GitLab.com
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

name "package-scripts"

# Help omnibus-ruby to cache the build product of this software. This is a
# workaround for the deprecation of `always_build true`. What happens now is
# that we build only if the contents of the specified directory have changed
# according to git.
default_version `git ls-tree HEAD -- config/templates/package-scripts | awk '{ print $3 }'`

build do
  # Create the package-script folder. The gitlab.rb project excludes this folder from the package.
  command "mkdir -p #{install_dir}/.package_util/package-scripts"

  # Render the package script erb files
  Dir.glob(File.join(Omnibus::Config.project_root, 'config/templates/package-scripts/*.erb')).each do |package_script|
    script = File.basename(package_script, '.*')
    erb :dest => "#{install_dir}/.package_util/package-scripts/#{script}",
        :source => File.basename(package_script),
        :mode => 0755,
        :vars => { :install_dir => project.install_dir }
  end
end
