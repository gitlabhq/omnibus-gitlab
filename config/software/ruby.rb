#
# Copyright 2012-2016 Chef Software, Inc.
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

name 'ruby'
license 'BSD-2-Clause'
license_file 'BSDL'
license_file 'COPYING'
license_file 'LEGAL'

skip_transitive_dependency_licensing true

# Follow the Ruby upgrade guide when changing the ruby version
# link: https://docs.gitlab.com/ee/development/ruby_upgrade.html
current_ruby_version = '3.0.5'

# NOTE: When this value is updated, flip `USE_NEXT_RUBY_VERSION_IN_*` variable
# to false to avoid surprises.
next_ruby_version = Gitlab::Util.get_env('NEXT_RUBY_VERSION') || '3.0.5'

# MRs targeting stable branches should use current Ruby version and ignore next
# Ruby version. Also, we provide `USE_OLD_RUBY_VERSION` variable to force usage
# of current Ruby version.
if Gitlab::Util.get_env('RUBY2_BUILD') == "true" || Gitlab::Util.get_env('USE_OLD_RUBY_VERSION') == "true" || Gitlab::Util.get_env('CI_MERGE_REQUEST_TARGET_BRANCH_NAME')&.match?(/^\d+-\d+-stable$/)
  default_version current_ruby_version
# Regular branch builds are switched to newer Ruby version first. So once the
# `NEXT_RUBY_VERSION` variable is updated, regular branches (master and feature
# branches) start bundling that version of Ruby. Because nightlies are also
# technically regular branch builds and because they get auto-deployed to
# dev.gitlab.org, we provide a variable `USE_NEXT_RUBY_VERSION_IN_NIGHTLY` to
# control it.
elsif (Build::Check.on_regular_branch? && !Build::Check.is_nightly?) || (Build::Check.is_nightly? && Gitlab::Util.get_env('USE_NEXT_RUBY_VERSION_IN_NIGHTLY') == "true")
  default_version next_ruby_version
# Once feature branches and nightlies have switched to newer Ruby version and
# we are ready to switch auto-deploy releases to GitLab.com to the new
# version, flipe the `USE_NEXT_RUBY_VERSION_IN_AUTODEPLOY` to `true`
elsif Build::Check.is_auto_deploy_tag? && Gitlab::Util.get_env('USE_NEXT_RUBY_VERSION_IN_AUTODEPLOY') == "true"
  default_version next_ruby_version
# Once we see new Ruby version running fine in GitLab.com, set new Ruby version
# as `current_ruby_version` so that they get used in stable branches and tag
# builds. This change marks "Switch Ruby to new version" as complete.
else
  default_version current_ruby_version
end

fips_enabled = Build::Check.use_system_ssl?

dependency 'zlib'
dependency 'openssl' unless Build::Check.use_system_ssl?
dependency 'libffi'
dependency 'libyaml'
# Needed for chef_gem installs of (e.g.) nokogiri on upgrades -
# they expect to see our libiconv instead of a system version.
dependency 'libiconv'
dependency 'jemalloc'

version('2.7.7') { source sha256: 'e10127db691d7ff36402cfe88f418c8d025a3f1eea92044b162dd72f0b8c7b90' }
version('3.0.5') { source sha256: '9afc6380a027a4fe1ae1a3e2eccb6b497b9c5ac0631c12ca56f9b7beb4848776' }

source url: "https://cache.ruby-lang.org/pub/ruby/#{version.match(/^(\d+\.\d+)/)[0]}/ruby-#{version}.tar.gz"

relative_path "ruby-#{version}"

env = with_standard_compiler_flags(with_embedded_path)

# Ruby will compile out the OpenSSL dyanmic checks for FIPS when
# OPENSSL_FIPS is not defined. RedHat always defines this macro in
# /usr/include/openssl/opensslconf-x86_64.h, but Ubuntu does not do
# this.
env['CFLAGS'] << " -DOPENSSL_FIPS" if Build::Check.use_system_ssl?

env['CFLAGS'] << ' -O3 -g -pipe'

# Workaround for https://bugs.ruby-lang.org/issues/19161
env['CFLAGS'] << ' -std=gnu99' if OhaiHelper.get_centos_version.to_i == 7 || OhaiHelper.os_platform == 'sles'

build do
  env['CFLAGS'] << ' -fno-omit-frame-pointer'
  # Fix for https://bugs.ruby-lang.org/issues/18409. This can be removed with Ruby 3.0+.
  env['LDFLAGS'] << ' -Wl,--no-as-needed'

  # disable libpath in mkmf across all platforms, it trolls omnibus and
  # breaks the postgresql cookbook.  i'm not sure why ruby authors decided
  # this was a good idea, but it breaks our use case hard.  AIX cannot even
  # compile without removing it, and it breaks some native gem installs on
  # other platforms.  generally you need to have a condition where the
  # embedded and non-embedded libs get into a fight (libiconv, openssl, etc)
  # and ruby trying to set LD_LIBRARY_PATH itself gets it wrong.
  if version.satisfies?('>= 2.1')
    patch source: 'ruby-mkmf.patch', plevel: 1, env: env
    # should intentionally break and fail to apply on 2.2, patch will need to
    # be fixed.
  end

  # Enable custom patch created by ayufan that allows to count memory allocations
  # per-thread. This is asked to be upstreamed as part of https://github.com/ruby/ruby/pull/3978
  if version.start_with?('2.7')
    patch source: 'thread-memory-allocations-2.7.patch', plevel: 1, env: env
  elsif version.start_with?('3.0')
    patch source: 'thread-memory-allocations-3.0.patch', plevel: 1, env: env
  elsif version.start_with?('3.1')
    patch source: 'thread-memory-allocations-3.1.patch', plevel: 1, env: env
  elsif version.start_with?('3.2')
    patch source: 'thread-memory-allocations-3.2.patch', plevel: 1, env: env
  end

  # copy_file_range() has been disabled on recent RedHat kernels:
  # 1. https://gitlab.com/gitlab-org/gitlab/-/issues/218999
  # 2. https://bugs.ruby-lang.org/issues/16965
  # 3. https://bugzilla.redhat.com/show_bug.cgi?id=1783554
  patch source: 'ruby-disable-copy-file-range.patch', plevel: 1, env: env if version.start_with?('2.7') && (centos? || rhel?)

  configure_command = ['--with-out-ext=dbm,readline',
                       '--enable-shared',
                       '--with-jemalloc',
                       '--disable-install-doc',
                       '--without-gmp',
                       '--without-gdbm',
                       '--without-tk',
                       '--disable-dtrace']
  configure_command << '--with-ext=psych' if version.satisfies?('< 2.3')
  configure_command << '--with-bundled-md5' if fips_enabled

  configure_command << %w(host target build).map { |w| "--#{w}=#{OhaiHelper.gcc_target}" } if OhaiHelper.raspberry_pi?

  configure_command << "--with-opt-dir=#{install_dir}/embedded"

  configure(*configure_command, env: env)
  make "-j #{workers}", env: env
  make "-j #{workers} install", env: env
end
