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
  name 'gitlab-ee'
  description 'GitLab Enterprise Edition '\
    '(including NGINX, Postgres, Redis)'
  replace 'gitlab-ce'
  conflict 'gitlab-ce'
else
  name 'gitlab-ce'
  description 'GitLab Community Edition '\
    '(including NGINX, Postgres, Redis)'
  replace 'gitlab-ee'
  conflict 'gitlab-ee'
end

maintainer 'GitLab Inc. <support@gitlab.com>'
homepage 'https://about.gitlab.com/'

license 'MIT'
license_compiled_output true

# Replace older omnibus-gitlab packages
replace         'gitlab'
conflict        'gitlab'

install_dir     '/opt/gitlab'

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

# Openssh needs to be installed

if suse?
  runtime_dependency 'openssh'
else
  runtime_dependency 'openssh-server'
end

# creates required build directories
dependency 'preparation'
dependency 'package-scripts'

dependency 'git'
dependency 'jemalloc'
dependency 'redis'
dependency 'nginx'
dependency 'mixlib-log'
dependency 'chef-zero'
dependency 'ohai'
dependency 'chef-gem'
dependency 'remote-syslog' if ee
dependency 'logrotate'
dependency 'runit'
dependency 'gitlab-rails'
dependency 'gitlab-shell'
dependency 'gitlab-workhorse'
dependency 'gitlab-ctl'
dependency 'gitlab-psql'
dependency 'gitlab-geo-psql' if ee
dependency 'gitlab-healthcheck'
dependency 'gitlab-cookbooks'
dependency 'gitlab-selinux'
dependency 'gitlab-scripts'
dependency 'gitlab-config-template'
dependency 'gitaly'
dependency 'mattermost'
dependency 'node-exporter'
dependency 'prometheus'
dependency 'redis-exporter'
dependency 'postgres-exporter'
dependency 'gitlab-monitor'

# version manifest file
dependency 'version-manifest'

exclude "\.git*"
exclude "bundler\/git"

# Our package scripts are generated from .erb files,
# so we will grab them from an excluded folder
package_scripts_path "#{install_dir}/.package_util/package-scripts"
exclude '.package_util'

package_user 'root'
package_group 'root'
