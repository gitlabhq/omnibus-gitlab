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

license "MIT"
license_compiled_output true

# Replace older omnibus-gitlab packages
replace         "gitlab"
conflict        "gitlab"

install_dir     "/opt/gitlab"
build_version   Omnibus::BuildVersion.new.semver
build_iteration Gitlab::BuildIteration.new.build_iteration

override :ruby, version: '2.1.8', source: { md5: '091b62f0a9796a3c55de2a228a0e6ef3' }
override :rubygems, version: '2.6.6'
override :'chef-gem', version: '12.12.15'
override :redis, version: '3.2.1', source: { md5: 'b311d4332326f1e6f86a461b4025636d' }
override :postgresql, version: '9.2.17', source: { md5: 'a75d4a82eae1edda04eda2e60656e74c' }
override :liblzma, version: '5.2.2', source: { md5: '7cf6a8544a7dae8e8106fdf7addfa28c' }
override :libxml2, version: '2.9.4', source: { md5: 'ae249165c173b1ff386ee8ad676815f5' }
override :pcre, version: '8.38', source: { md5: '8a353fe1450216b6655dfcf3561716d9', url: "http://downloads.sourceforge.net/project/pcre/pcre/8.38/pcre-8.38.tar.gz" }
override :expat, version: '2.1.1', source: { md5: '7380a64a8e3a9d66a9887b01d0d7ea81', url: "http://downloads.sourceforge.net/project/expat/expat/2.1.1/expat-2.1.1.tar.bz2" }
override :config_guess, source: {git: "git@dev.gitlab.org:omnibus-mirror/config_guess.git" } # Original git://git.sv.gnu.org/config.git is failing intermittently

# Openssh needs to be installed
runtime_dependency "openssh-server"

# creates required build directories
dependency "preparation"
dependency "package-scripts"

dependency "git"
dependency "redis"
dependency "nginx"
dependency "mixlib-log"
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
dependency "gitlab-psql"
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
