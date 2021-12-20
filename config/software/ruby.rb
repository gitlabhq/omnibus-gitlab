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

# Follow the Ruby upgrade guidelines when changing the ruby version
# link: https://docs.gitlab.com/ee/development/ruby_upgrade.html
default_version '2.7.5'

fips_enabled = (project.overrides[:fips] && project.overrides[:fips][:enabled]) || false

dependency 'zlib'
dependency 'openssl' unless Build::Check.use_system_ssl?
dependency 'libffi'
dependency 'libyaml'
# Needed for chef_gem installs of (e.g.) nokogiri on upgrades -
# they expect to see our libiconv instead of a system version.
dependency 'libiconv'

version('2.7.5') { source sha256: '2755b900a21235b443bb16dadd9032f784d4a88f143d852bc5d154f22b8781f1' }

source url: "https://cache.ruby-lang.org/pub/ruby/#{version.match(/^(\d+\.\d+)/)[0]}/ruby-#{version}.tar.gz"

relative_path "ruby-#{version}"

env = with_standard_compiler_flags(with_embedded_path)

env['CFLAGS'] << if version.satisfies?('>= 2.3.0') &&
    rhel? && platform_version.satisfies?('< 6.0')
                   ' -O2 -g -pipe'
                 else
                   ' -O3 -g -pipe'
                 end

build do
  env['CFLAGS'] << ' -fno-omit-frame-pointer'

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
  patch source: 'thread-memory-allocations-2.7.patch', plevel: 1, env: env

  # Fix reserve stack segmentation fault when building on RHEL5 or below
  # Currently only affects 2.1.7 and 2.2.3. This patch taken from the fix
  # in Ruby trunk and expected to be included in future point releases.
  # https://redmine.ruby-lang.org/issues/11602
  if rhel? &&
      platform_version.satisfies?('< 6') &&
      (version == '2.1.7' || version == '2.2.3')

    patch source: 'ruby-fix-reserve-stack-segfault.patch', plevel: 1, env: env
  end

  # copy_file_range() has been disabled on recent RedHat kernels:
  # 1. https://gitlab.com/gitlab-org/gitlab/-/issues/218999
  # 2. https://bugs.ruby-lang.org/issues/16965
  # 3. https://bugzilla.redhat.com/show_bug.cgi?id=1783554
  patch source: 'ruby-disable-copy-file-range.patch', plevel: 1, env: env if centos? || rhel?

  configure_command = ['--with-out-ext=dbm,readline',
                       '--enable-shared',
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
