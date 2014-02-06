#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

name "gitlab-core"
version "master"

dependency "ruby"
dependency "bundler"
dependency "libxml2"
dependency "libxslt"
dependency "curl"
dependency "rsync"
dependency "libicu"
dependency "postgresql"

source :git => "https://gitlab.com/gitlab-org/gitlab-ce.git"

build do
  # GitLab assumes it can extract the Git revision of the currently version
  # from the Git repo the code lives in at boot. Because of our rsync later on,
  # this assumption does not hold. The sed command below patches the GitLab
  # source code to include the Git revision of the code included in the omnibus
  # build.
  command "sed -i 's/.*REVISION.*/REVISION = \"#{version_guid.split(':').last[0,10]}\"/' config/initializers/2_app.rb"
  bundle "install --without mysql development test --path=#{install_dir}/embedded/service/gem"
  command "mkdir -p #{install_dir}/embedded/service/gitlab-core"
  command "#{install_dir}/embedded/bin/rsync -a --delete --exclude=.git/*** --exclude=.gitignore ./ #{install_dir}/embedded/service/gitlab-core/"
end
