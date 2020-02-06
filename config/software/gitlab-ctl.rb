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

name 'gitlab-ctl'

license 'Apache-2.0'
license_file File.expand_path('LICENSE', Omnibus::Config.project_root)

skip_transitive_dependency_licensing true

dependency 'omnibus-ctl'

source path: File.expand_path('files/gitlab-ctl-commands', Omnibus::Config.project_root)

build do
  command "mkdir -p #{install_dir}/bin/"

  block do
    File.open("#{install_dir}/bin/gitlab-ctl", 'w') do |file|
      file.print <<-EOH
#!/bin/bash
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

# Ensure the calling environment (disapproval look Bundler) does not infect our
# Ruby environment if gitlab-ctl is called from a Ruby script.
for ruby_env_var in RUBYOPT \\
                    RUBYLIB \\
                    BUNDLE_BIN_PATH \\
                    BUNDLE_GEMFILE \\
                    GEM_PATH \\
                    GEM_HOME
do
  unset $ruby_env_var
done

# This bumps the default svwait timeout from 7 seconds to 30 seconds
# As documented at http://smarden.org/runit/sv.8.html
export SVWAIT=30

if [ "$1" == "reconfigure" ] && [ "$UID" != "0" ]; then
  echo "This command must be executed as root user"
  exit 1
fi

#{install_dir}/embedded/bin/omnibus-ctl #{File.basename(install_dir)} '#{install_dir}/embedded/service/omnibus-ctl*' "$@"
      EOH
    end
  end

  command "chmod 755 #{install_dir}/bin/gitlab-ctl"

  # additional omnibus-ctl commands
  sync './', "#{install_dir}/embedded/service/omnibus-ctl/"
end
