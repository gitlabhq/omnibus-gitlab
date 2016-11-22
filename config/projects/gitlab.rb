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
require "#{Omnibus::Config.project_root}/lib/gitlab/version"

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

# This is a hack to make a distinction between nightly versions
# See https://gitlab.com/gitlab-org/omnibus-gitlab/issues/1500
#
# This will be resolved as part of
# https://gitlab.com/gitlab-org/omnibus-gitlab/issues/1007
#
# Also check support/release_version.rb for Docker version forming
if ENV['NIGHTLY'] && ENV['CI_PIPELINE_ID']
  build_version "#{Omnibus::BuildVersion.new.semver}.#{ENV['CI_PIPELINE_ID']}"
else
  build_version Omnibus::BuildVersion.new.semver
end
build_iteration Gitlab::BuildIteration.new.build_iteration

# Overrides for remote URLs of the software
#
# Original git://git.sv.gnu.org/config.git is failing intermittently
config_guess_version =  Gitlab::Version.new('config_guess', "master")

override :ruby, version: '2.3.1', source: { md5: '0d896c2e7fd54f722b399f407e48a4c6' }
override :rubygems, version: '2.6.6'
override :'chef-gem', version: '12.12.15'
override :redis, version: '3.2.5', source: { md5: 'd3d2b4dd4b2a3e07ee6f63c526b66b08' }
override :liblzma, version: '5.2.2', source: { md5: '7cf6a8544a7dae8e8106fdf7addfa28c' }
override :libxml2, version: '2.9.4', source: { md5: 'ae249165c173b1ff386ee8ad676815f5' }
override :pcre, version: '8.38', source: { md5: '8a353fe1450216b6655dfcf3561716d9', url: "http://downloads.sourceforge.net/project/pcre/pcre/8.38/pcre-8.38.tar.gz" }
override :expat, version: '2.2.0', source: { md5: '2f47841c829facb346eb6e3fab5212e2', url: "http://downloads.sourceforge.net/project/expat/expat/2.2.0/expat-2.2.0.tar.bz2" }
override :config_guess, version: config_guess_version.print, source: { git: config_guess_version.remote }
override :rsync, version: '3.1.2'

# Openssh needs to be installed

if suse?
  runtime_dependency "openssh"
else
  runtime_dependency "openssh-server"
end

# creates required build directories
dependency "preparation"
dependency "package-scripts"

dependency "git"
dependency "jemalloc"
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
