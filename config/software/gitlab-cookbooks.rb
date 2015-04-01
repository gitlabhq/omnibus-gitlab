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

dependency "rsync"

# Help omnibus-ruby to cache the build product of this software. This is a
# workaround for the deprecation of `always_build true`. What happens now is
# that we build only if the contents of the specified directory have changed
# according to git.
version `git ls-tree HEAD -- files/gitlab-cookbooks | awk '{ print $3 }'`

source :path => File.expand_path("files/gitlab-cookbooks", Omnibus::Config.project_root)

build do
  command "mkdir -p #{install_dir}/embedded/cookbooks"
  command "#{install_dir}/embedded/bin/rsync --delete -a ./ #{install_dir}/embedded/cookbooks/"
end
