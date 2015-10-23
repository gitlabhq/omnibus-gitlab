#
## Copyright:: Copyright (c) 2013, 2014 GitLab.com
## License:: Apache License, Version 2.0
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

require "#{Omnibus::Config.project_root}/lib/gitlab/build_iteration"

ee = system("#{Omnibus::Config.project_root}/support/is_gitlab_ee.sh")

if ee
  name "gitlab-ee"
  description "GitLab Enterprise Edition and GitLab CI "\
    "(including NGINX, Postgres, Redis)"
  replace        "gitlab-ce"
  conflict        "gitlab-ce"
else
  name "gitlab-ce"
  description "GitLab Community Edition and GitLab CI "\
    "(including NGINX, Postgres, Redis)"
  replace        "gitlab-ee"
  conflict        "gitlab-ee"
end

maintainer "GitLab B.V."
homepage "https://about.gitlab.com/"

# Replace older omnibus-gitlab packages
replace         "gitlab"
conflict        "gitlab"

install_dir     "/opt/gitlab"
build_version   Omnibus::BuildVersion.new.semver
build_iteration Gitlab::BuildIteration.new.build_iteration

override :ruby, version: '2.1.7'
override :rubygems, version: 'ccfafdc2c52c5c605ff69ed3a772d83eb19ef55a' # 2.2.5
override :'chef-gem', version: '12.5.1'
override :cacerts, version: '2015.09.02', source: { md5: '3e0e6f302bd4f5b94040b8bcee0ffe15' }
override :openssl, version: '1.0.1p', source: { url: 'https://www.openssl.org/source/openssl-1.0.1p.tar.gz', md5: '7563e92327199e0067ccd0f79f436976' }

# Openssh needs to be installed
runtime_dependency "openssh-server"

# creates required build directories
dependency "preparation"
dependency "package-scripts"

dependency "git"
dependency "redis"
dependency "nginx"
dependency "chef-gem"
dependency "remote-syslog" if ee
dependency "logrotate"
dependency "runit"
dependency "nodejs"
dependency "gitlab-ci"
dependency "gitlab-rails"
dependency "gitlab-shell"
dependency "gitlab-git-http-server"
dependency "gitlab-ctl"
dependency "gitlab-cookbooks"
dependency "gitlab-selinux"
dependency "gitlab-scripts"
dependency "gitlab-config-template"
dependency "mattermost"

# version manifest file
dependency "version-manifest"

exclude "\.git*"
exclude "bundler\/git"

# Our package scripts are generated from .erb files,
# so we will grab them from an excluded folder
package_scripts_path "#{install_dir}/.package_util/package-scripts"
exclude '.package_util'

package_user 'root'
package_group 'root'
