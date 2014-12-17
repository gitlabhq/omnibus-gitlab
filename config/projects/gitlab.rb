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

name "gitlab"
maintainer "GitLab.com"
homepage "https://about.gitlab.com/"

replaces        "gitlab"
install_dir     "/opt/gitlab"
build_version   Omnibus::BuildVersion.new.semver
build_iteration 1

override :ruby, version: '2.1.4'
override :rubygems, version: '2.2.1'

# creates required build directories
dependency "preparation"

dependency "git"
dependency "redis"
dependency "nginx"
dependency "chef-gem"
if system("#{Config.project_root}/support/is_gitlab_ee.sh") || system("#{Config.project_root}/support/is_gitlab_com.sh")
  dependency "remote-syslog"
end
dependency "logrotate"
dependency "runit"
dependency "gitlab-ci"
dependency "gitlab-rails"
dependency "gitlab-shell"
dependency "gitlab-ctl"
dependency "gitlab-cookbooks"
dependency "gitlab-selinux"
dependency "gitlab-config-template"
dependency "byacc"
dependency "krb5"

# version manifest file
dependency "version-manifest"

exclude "\.git*"
exclude "bundler\/git"

package_user 'root'
package_group 'root'
