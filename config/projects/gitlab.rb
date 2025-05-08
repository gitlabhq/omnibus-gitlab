#
## Copyright:: Copyright (c) 2013, 2014 GitLab Inc.
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
require "#{Omnibus::Config.project_root}/lib/gitlab/build/info/package"
require "#{Omnibus::Config.project_root}/lib/gitlab/version"
require "#{Omnibus::Config.project_root}/lib/gitlab/util"
require "#{Omnibus::Config.project_root}/lib/gitlab/ohai_helper.rb"
require "#{Omnibus::Config.project_root}/lib/gitlab/openssl_helper"
require "#{Omnibus::Config.project_root}/files/gitlab-cookbooks/package/libraries/helpers/selinux_distro_helper.rb"

gitlab_package_name = Build::Info::Package.name
gitlab_package_file = File.join(Omnibus::Config.project_dir, 'gitlab', "#{gitlab_package_name}.rb")

# Include package specific details like package name and descrption (for gitlab-ee/gitlab-ce/etc)
instance_eval(IO.read(gitlab_package_file), gitlab_package_file, 1)

# Include all other known gitlab packages in our replace/conflict list to allow transitioning between packages
Dir.glob(File.join(Omnibus::Config.project_dir, 'gitlab', '*.rb')).each do |filename|
  other_package = File.basename(filename, '.rb')
  next if other_package == gitlab_package_name

  replace other_package
  conflict other_package
end

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
build_version Build::Info::Package.semver_version
build_iteration Gitlab::BuildIteration.new.build_iteration

# Openssh needs to be installed

if suse?
  runtime_dependency 'openssh'
else
  runtime_dependency 'openssh-server'
end

# perl is required for exiftool and openssh certificate hashing

if rhel?
  case OhaiHelper.get_centos_version
  when '8', '9'
    runtime_dependency 'policycoreutils-python-utils'
    runtime_dependency 'perl-interpreter'
  end
elsif amazon?
  case OhaiHelper.get_amazon_version
  when '2'
    runtime_dependency 'policycoreutils-python'
    runtime_dependency 'perl'
  when '2023'
    runtime_dependency 'policycoreutils-python-utils'
    runtime_dependency 'perl-interpreter'
  end
else
  runtime_dependency 'perl'
end

# Arm targets need libatomic
if OhaiHelper.arm?
  if rhel? || amazon?
    runtime_dependency 'libatomic'
  else
    runtime_dependency 'libatomic1'
  end

  allowed_lib /libatomic.so.1/ if OhaiHelper.raspberry_pi?
end

# FIPS requires system OpenSSL packages to run
if Build::Check.use_system_ssl?
  if rhel?
    runtime_dependency 'openssl-perl'
  else
    runtime_dependency 'openssl'
  end
end

# FIPS requires system libgcrypt packages to run.
if Build::Check.use_system_libgcrypt?
  allowed_lib /libgcrypt\.so/

  if rhel? || amazon?
    runtime_dependency 'libgcrypt'
  else
    runtime_dependency 'libgcrypt20'
  end
end

dependency 'cacerts'
dependency 'omnibus-gitlab-gems'
dependency 'gitlab-selinux' if SELinuxDistroHelper.selinux_supported?
dependency 'redis'
dependency 'nginx'
dependency 'chef-gem'
dependency 'inspec-gem'
dependency 'logrotate'
dependency 'runit'
dependency 'go-crond'
dependency 'docker-distribution-pruner'

if Build::Check.include_ee?
  dependency 'consul'
  dependency 'pgbouncer-exporter'
  unless OhaiHelper.raspberry_pi?
    dependency 'spamcheck'
    dependency 'spam-classifier'
  end
end
dependency 'alertmanager'
dependency 'node-exporter'
dependency 'redis-exporter'
dependency 'postgres-exporter'
dependency 'prometheus'
dependency 'gitlab-exporter'
dependency 'mattermost'

# Components that depend on the contents of this repository tends to dirty the
# cache frequently than vendored components.
if Build::Check.include_ee?
  dependency 'gitlab-ctl-ee'
  dependency 'gitlab-geo-psql'
  dependency 'gitlab-pg-ctl'
end
dependency 'gitlab-cookbooks'
dependency 'chef-acme'
dependency 'gitlab-ctl'
dependency 'gitlab-psql'
dependency 'gitlab-backup-cli'
dependency 'gitlab-redis-cli'
dependency 'gitlab-healthcheck'

dependency 'gitlab-scripts'
dependency 'gitlab-config-template'

# Build GitLab components at the end because except for tag pipelines, we build
# from `main`/`master`, and this can invalidate cache easily. Git is built from
# gitaly sources, and hence falls under the same category.
dependency 'gitlab-elasticsearch-indexer' if Build::Check.include_ee?

dependency 'gitlab-kas'
dependency 'gitlab-shell'
dependency 'gitlab-pages'
dependency 'git'

# `git-filter-repo` is a dependency of Gitaly. But placing it there will cause
# it to be built early in the build list, which will in-turn cause `git` to be
# built early. `git`, being built from `gitaly` source will bust cache often,
# and cause unnecessary rebuilds. Hence, we are placing `git-filter-repo` as a
# project dependency after `git`
dependency 'git-filter-repo'

# gitaly needs grpc to work correctly. These native extensions are built as part
# of gitlab-rails build. So, gitlab-rails has to be built before gitaly. But
# making gitaly depend on gitlab-rails will cause it to be built earlier,
# because of the ordering omnibus applies to transitive dependencies.  Building
# gitlab-rails earlier in the sequence is a problem as we expect this component to
# churn a lot, invalidating the build cache for later component builds.
# https://github.com/chef/omnibus/blob/master/docs/Build%20Cache.md
dependency 'gitlab-rails'
dependency 'gitaly'
dependency 'ruby-grpc' if Build::Check.use_system_ssl?

# Package scripts
dependency 'package-scripts'
# version manifest file
dependency 'version-manifest'

if Build::Check.use_system_ssl?
  OpenSSLHelper.allowed_libs.each do |lib|
    allowed_lib /#{lib}\.so/
  end
end

exclude "\.git*"
exclude "bundler\/git"

# don't ship source code needed to build
exclude 'src'

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
exclude 'embedded/lib/ruby/gems/*/gems/*/*.ruby'
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

# Exclude additional files from specific gems
exclude 'embedded/lib/ruby/gems/*/gems/grpc-*/include'
exclude 'embedded/lib/ruby/gems/*/gems/grpc-*/src/core'
exclude 'embedded/lib/ruby/gems/*/gems/grpc-*/src/ruby/ext'
exclude 'embedded/lib/ruby/gems/*/gems/grpc-*/src/ruby/spec'
exclude 'embedded/lib/ruby/gems/*/gems/grpc-*/third_party'
exclude 'embedded/lib/ruby/gems/*/gems/nokogumbo-*/ext'
exclude 'embedded/lib/ruby/gems/*/gems/rbtrace-*/ext/src'
exclude 'embedded/lib/ruby/gems/*/gems/rbtrace-*/ext/dst'
exclude 'embedded/lib/ruby/gems/*/gems/re2-*/ports'
exclude 'embedded/lib/ruby/gems/*/gems/*pg_query-*/ext'

# Exclude exe files from Python libraries
exclude 'embedded/lib/python*/**/*.exe'
# Exclude whl files from Python libraries.
exclude 'embedded/lib/python*/**/*.whl'

# Enable signing packages
package :rpm do
  vendor 'GitLab, Inc. <support@gitlab.com>'
  signing_passphrase Gitlab::Util.get_env('GPG_PASSPHRASE')

  # Enable XZ compression if selected
  compress_xz = Gitlab::Util.get_env('COMPRESS_XZ') || 'true'
  if compress_xz == 'true'
    compression_type :xz
    compression_level 6
  end
end

package :deb do
  vendor 'GitLab, Inc. <support@gitlab.com>'
  signing_passphrase Gitlab::Util.get_env('GPG_PASSPHRASE')

  # Enable XZ compression if selected
  compress_xz = Gitlab::Util.get_env('COMPRESS_XZ') || 'true'
  if compress_xz == 'true'
    compression_type :xz
    compression_level 6
  end
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

# exclude Spamcheck application source and libraries
exclude 'embedded/service/spamcheck/app'

package_user 'root'
package_group 'root'
