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
ee = system("#{Omnibus::Config.project_root}/support/is_gitlab_ee.sh") || system("#{Omnibus::Config.project_root}/support/is_gitlab_com.sh")

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
build_iteration 1

override :ruby, version: '2.1.6',  source: { md5: "6e5564364be085c45576787b48eeb75f" }
override :rubygems, version: '2.2.1'
override :chef, version: '12.4.0.rc.0'
override :'omnibus-ctl', version: '0.3.4'
override :zlib, version: '1.2.8'
override :cacerts, version: '2015.04.22', source: { md5: '380df856e8f789c1af97d0da9a243769' }

# Openssh needs to be installed
runtime_dependency "openssh-server"

# creates required build directories
dependency "preparation"

dependency "git"
dependency "redis"
dependency "nginx"
dependency "chef"
dependency "remote-syslog" if ee
dependency "logrotate"
dependency "runit"
dependency "nodejs"
dependency "gitlab-ci"
dependency "gitlab-rails"
dependency "gitlab-shell"
dependency "gitlab-ctl"
dependency "gitlab-cookbooks"
dependency "gitlab-selinux"
dependency "gitlab-config-template"

# version manifest file
dependency "version-manifest"

exclude "\.git*"
exclude "bundler\/git"

# Because we have a dynamic 'name' (gitlab-ce or gitlab-ee), omnibus-ruby would
# look in either package-scripts/gitlab-ce or package-scripts/gitlab-ee. We
# don't want that so let's hard-code the path.
package_scripts_path "#{Omnibus::Config.project_root}/package-scripts/gitlab"

package_user 'root'
package_group 'root'
