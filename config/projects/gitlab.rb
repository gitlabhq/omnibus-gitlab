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
require "#{Omnibus::Config.project_root}/lib/gitlab/build/info"
require "#{Omnibus::Config.project_root}/lib/gitlab/version"
require "#{Omnibus::Config.project_root}/lib/gitlab/util"
require "#{Omnibus::Config.project_root}/lib/gitlab/ohai_helper.rb"

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

maintainer 'GitLab, Inc. <support@gitlab.com>'
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
# Also check lib/gitlab/build.rb for Docker version forming
build_version Build::Info.semver_version
build_iteration Gitlab::BuildIteration.new.build_iteration

# Openssh needs to be installed

if suse?
  runtime_dependency 'openssh'
else
  runtime_dependency 'openssh-server'
end

if rhel?
  case OhaiHelper.get_centos_version
  when '6', '7'
    runtime_dependency 'policycoreutils-python'
  when '8'
    runtime_dependency 'policycoreutils-python-utils'
  end
end

# Arm targets need libatomic
runtime_dependency 'libatomic1' if OhaiHelper.arm?

dependency 'git'
dependency 'jemalloc'
dependency 'redis'
dependency 'nginx'
dependency 'mixlib-log'
dependency 'chef-zero'
dependency 'awesome_print'
dependency 'ohai'
dependency 'chef-gem'
dependency 'chef-bin'
dependency 'remote-syslog'
dependency 'logrotate'
dependency 'runit'
dependency 'go-crond'
dependency 'docker-distribution-pruner'

if ee
  dependency 'consul'
  dependency 'gitlab-ctl-ee'
  dependency 'gitlab-geo-psql'
  dependency 'gitlab-pg-ctl'
  dependency 'pgbouncer-exporter'
end
dependency 'mattermost'
dependency 'prometheus'
dependency 'alertmanager'
dependency 'grafana'
dependency 'grafana-dashboards'
dependency 'node-exporter'
dependency 'redis-exporter'
dependency 'postgres-exporter'
dependency 'gitlab-exporter'
dependency 'gitlab-workhorse'
dependency 'gitlab-shell'
dependency 'gitlab-ctl'
dependency 'gitlab-psql'
dependency 'gitlab-redis-cli'
dependency 'gitlab-healthcheck'
dependency 'gitlab-cookbooks'
dependency 'chef-acme'
dependency 'gitlab-selinux'
dependency 'gitlab-scripts'
dependency 'gitlab-config-template'
dependency 'package-scripts'

# gitaly needs grpc to work correctly. These native extensions are built as part
# of gitlab-rails build. So, gitlab-rails has to be built before gitaly. But
# making gitaly depend on gitlab-rails will cause it to be built earlier,
# because of the ordering omnibus applies to transitive dependencies.  Building
# gitlab-rails earlier in the sequence is a problem as we expect this component to
# churn a lot, invalidating the build cache for later component builds.
# https://github.com/chef/omnibus/blob/master/docs/Build%20Cache.md
dependency 'gitlab-rails'
dependency 'gitaly'

# version manifest file
dependency 'version-manifest'

exclude "\.git*"
exclude "bundler\/git"

# don't ship static libraries or header files
exclude 'embedded/lib/**/*.a'
exclude 'embedded/lib/**/*.la'
exclude 'embedded/include'

# exclude manpages and documentation
exclude 'embedded/man'
exclude 'embedded/share/doc'
exclude 'embedded/share/gtk-doc'
exclude 'embedded/share/info'
exclude 'embedded/share/man'

# exclude rubygems build cache
exclude 'embedded/lib/ruby/gems/*/cache'

# exclude test and some vendor folders
exclude 'embedded/lib/ruby/gems/*/gems/*/spec'
exclude 'embedded/lib/ruby/gems/*/gems/*/test'
exclude 'embedded/lib/ruby/gems/*/gems/*/tests'
# Some vendor folders (e.g. licensee) are needed by GitLab.
# For now, exclude the most space-consuming gems until
# there's a better way to whitelist directories.
exclude 'embedded/lib/ruby/gems/*/gems/rugged*/vendor'
exclude 'embedded/lib/ruby/gems/*/gems/ace-rails*/vendor'
exclude 'embedded/lib/ruby/gems/*/gems/libyajl2*/**/vendor'

# exclude gem build logs
exclude 'embedded/lib/ruby/gems/*/extensions/*/*/*/mkmf.log'
exclude 'embedded/lib/ruby/gems/*/extensions/*/*/*/gem_make.out'

# # exclude C sources
exclude 'embedded/lib/ruby/gems/*/gems/*/ext/*.c'
exclude 'embedded/lib/ruby/gems/*/gems/*/ext/*/*.c'
exclude 'embedded/lib/ruby/gems/*/gems/*/ext/*.o'
exclude 'embedded/lib/ruby/gems/*/gems/*/ext/*/*.o'

# # exclude other gem files
exclude 'embedded/lib/ruby/gems/*/gems/*/*.gemspec'
exclude 'embedded/lib/ruby/gems/*/gems/*/*.md'
exclude 'embedded/lib/ruby/gems/*/gems/*/*.rdoc'
exclude 'embedded/lib/ruby/gems/*/gems/*/*.sh'
exclude 'embedded/lib/ruby/gems/*/gems/*/*.txt'
exclude 'embedded/lib/ruby/gems/*/gems/*/*LICENSE*'
exclude 'embedded/lib/ruby/gems/*/gems/*/CHANGES*'
exclude 'embedded/lib/ruby/gems/*/gems/*/Gemfile'
exclude 'embedded/lib/ruby/gems/*/gems/*/Guardfile'
exclude 'embedded/lib/ruby/gems/*/gems/*/README*'
exclude 'embedded/lib/ruby/gems/*/gems/*/Rakefile'
exclude 'embedded/lib/ruby/gems/*/gems/*/run_tests.rb'

exclude 'embedded/lib/ruby/gems/*/gems/*/Documentation'
exclude 'embedded/lib/ruby/gems/*/gems/*/bench'
exclude 'embedded/lib/ruby/gems/*/gems/*/contrib'
exclude 'embedded/lib/ruby/gems/*/gems/*/doc'
exclude 'embedded/lib/ruby/gems/*/gems/*/doc-api'
exclude 'embedded/lib/ruby/gems/*/gems/*/examples'
exclude 'embedded/lib/ruby/gems/*/gems/*/fixtures'
exclude 'embedded/lib/ruby/gems/*/gems/*/gemfiles'
exclude 'embedded/lib/ruby/gems/*/gems/*/libtest'
exclude 'embedded/lib/ruby/gems/*/gems/*/man'
exclude 'embedded/lib/ruby/gems/*/gems/*/sample_documents'
exclude 'embedded/lib/ruby/gems/*/gems/*/samples'
exclude 'embedded/lib/ruby/gems/*/gems/*/sample'
exclude 'embedded/lib/ruby/gems/*/gems/*/script'
exclude 'embedded/lib/ruby/gems/*/gems/*/t'

# Exclude additional test files from specific gems
exclude 'embedded/lib/ruby/gems/*/gems/grpc-*/src/ruby/spec'

# Enable signing packages
package :rpm do
  signing_passphrase Gitlab::Util.get_env('GPG_PASSPHRASE')
end

package :deb do
  signing_passphrase Gitlab::Util.get_env('GPG_PASSPHRASE')
end

resources_path "#{Omnibus::Config.project_root}/resources"

# Our package scripts are generated from .erb files,
# so we will grab them from an excluded folder
package_scripts_path "#{install_dir}/.package_util/package-scripts"
exclude '.package_util'

# Exclude Python cache and distribution info
exclude 'embedded/lib/python*/**/*.dist-info'
exclude 'embedded/lib/python*/**/*.egg-info'
exclude 'embedded/lib/python*/**/__pycache__'

package_user 'root'
package_group 'root'
