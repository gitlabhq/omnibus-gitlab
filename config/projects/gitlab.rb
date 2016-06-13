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

maintainer "GitLab Inc. <support@gitlab.com>"
homepage "https://about.gitlab.com/"

# Replace older omnibus-gitlab packages
replace         "gitlab"
conflict        "gitlab"

install_dir     "/opt/gitlab"
build_version   Omnibus::BuildVersion.new.semver
build_iteration Gitlab::BuildIteration.new.build_iteration

override :ruby, version: '2.1.8', source: { md5: '091b62f0a9796a3c55de2a228a0e6ef3' }
override :rubygems, version: 'v2.5.1'
override :'chef-gem', version: '12.6.0'
override :cacerts, version: '2016.04.20', source: { md5: '782dcde8f5d53b1b9e888fdf113c42b9' }
override :pip, version: '7.1.2', source: { md5: '3823d2343d9f3aaab21cf9c917710196' }
override :redis, version: '2.8.24', source: { md5: '7b6eb6e4ccc050c351df8ae83c55a035' }
override :postgresql, version: '9.2.15', source: { md5: '235b4fc09eff4569a7972be65c449ecc' }
override :liblzma, version: '5.2.2', source: { md5: '7cf6a8544a7dae8e8106fdf7addfa28c' }
override :pcre, version: '8.38', source: { md5: '8a353fe1450216b6655dfcf3561716d9' }
override :expat, version: '2.1.1', source: { md5: '7380a64a8e3a9d66a9887b01d0d7ea81', url: "http://iweb.dl.sourceforge.net/project/expat/expat/2.1.1/expat-2.1.1.tar.bz2" }

# Openssh needs to be installed
runtime_dependency "openssh-server"

# creates required build directories
dependency "preparation"
dependency "package-scripts"

dependency "git"
dependency "redis"
dependency "nginx"
dependency "chef-zero"
dependency "ohai"
dependency "chef-gem"
dependency "remote-syslog" if ee
dependency "logrotate"
dependency "runit"
dependency "nodejs"
dependency "gitlab-rails"
dependency "gitlab-shell"
dependency "gitlab-workhorse"
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
