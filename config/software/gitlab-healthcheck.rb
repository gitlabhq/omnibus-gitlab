#
# Copyright:: Copyright (c) 2016 GitLab Inc.
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

name 'gitlab-healthcheck'

license 'Apache-2.0'
license_file File.expand_path('LICENSE', Omnibus::Config.project_root)

skip_transitive_dependency_licensing true

# This 'software' is self-contained in this file. Use the file contents
# to generate a version string.
default_version Digest::MD5.file(__FILE__).hexdigest

build do
  block do
    File.open("#{install_dir}/bin/gitlab-healthcheck", 'w') do |file|
      file.print <<-EOH
#!/bin/sh

error_echo()
{
  echo "$1" 2>& 1
}

gitlab_healthcheck_rc='/opt/gitlab/etc/gitlab-healthcheck-rc'


if ! [ -f ${gitlab_healthcheck_rc} ] ; then
  exit 1
fi

. ${gitlab_healthcheck_rc}

exec /opt/gitlab/embedded/bin/curl $@ ${flags} ${url}
      EOH
    end
  end

  command "chmod 755 #{install_dir}/bin/gitlab-healthcheck"
end
