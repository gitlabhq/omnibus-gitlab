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
current_ruby_version = Gitlab::Util.get_env('RUBY_VERSION') || '3.2.8'

# NOTE: When this value is updated, flip `USE_NEXT_RUBY_VERSION_IN_*` variable
# to false to avoid surprises.
next_ruby_version = Gitlab::Util.get_env('NEXT_RUBY_VERSION') || '3.4.8'

# MRs targeting stable branches should use current Ruby version and ignore next
# Ruby version. Also, we provide `USE_SPECIFIED_RUBY_VERSION` variable to force
# usage of specified Ruby version.
if Gitlab::Util.get_env('USE_SPECIFIED_RUBY_VERSION') == "true" || Gitlab::Util.get_env('CI_MERGE_REQUEST_TARGET_BRANCH_NAME')&.match?(/^\d+-\d+-stable$/)
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
# version, flip the `USE_NEXT_RUBY_VERSION_IN_AUTODEPLOY` to `true`
elsif Build::Check.is_auto_deploy_tag? && Gitlab::Util.get_env('USE_NEXT_RUBY_VERSION_IN_AUTODEPLOY') == "true"
  default_version next_ruby_version
# Once we see new Ruby version running fine in GitLab.com, set new Ruby version
# as `current_ruby_version` so that they get used in stable branches and tag
# builds. This change marks "Switch Ruby to new version" as complete.
else
  default_version current_ruby_version
end

fips_enabled = Build::Check.use_system_ssl?

dependency 'zlib-ng'
dependency 'openssl' unless Build::Check.use_system_ssl?
dependency 'libffi'
dependency 'libyaml'
# Needed for chef_gem installs of (e.g.) nokogiri on upgrades -
# they expect to see our libiconv instead of a system version.
dependency 'libiconv'
dependency 'jemalloc'

version('3.1.5') { source sha256: '3685c51eeee1352c31ea039706d71976f53d00ab6d77312de6aa1abaf5cda2c5' }
version('3.2.3') { source sha256: 'af7f1757d9ddb630345988139211f1fd570ff5ba830def1cc7c468ae9b65c9ba' }
version('3.2.4') { source sha256: 'c72b3c5c30482dca18b0f868c9075f3f47d8168eaf626d4e682ce5b59c858692' }
version('3.2.5') { source sha256: 'ef0610b498f60fb5cfd77b51adb3c10f4ca8ed9a17cb87c61e5bea314ac34a16' }
version('3.2.6') { source sha256: 'd9cb65ecdf3f18669639f2638b63379ed6fbb17d93ae4e726d4eb2bf68a48370' }
version('3.2.8') { source sha256: '77acdd8cfbbe1f8e573b5e6536e03c5103df989dc05fa68c70f011833c356075' }
version('3.2.9') { source sha256: 'abbad98db9aeb152773b0d35868e50003b8c467f3d06152577c4dfed9d88ed2a' }
version('3.3.6') { source sha256: '8dc48fffaf270f86f1019053f28e51e4da4cce32a36760a0603a9aee67d7fd8d' }
version('3.3.7') { source sha256: '9c37c3b12288c7aec20ca121ce76845be5bb5d77662a24919651aaf1d12c8628' }
version('3.3.8') { source sha256: '5ae28a87a59a3e4ad66bc2931d232dbab953d0aa8f6baf3bc4f8f80977c89cab' }
version('3.3.9') { source sha256: 'd1991690a4e17233ec6b3c7844c1e1245c0adce3e00d713551d0458467b727b1' }
version('3.3.10') { source sha256: 'b555baa467a306cfc8e6c6ed24d0d27b27e9a1bed1d91d95509859eac6b0e928' }
version('3.4.2') { source sha256: '41328ac21f2bfdd7de6b3565ef4f0dd7543354d37e96f157a1552a6bd0eb364b' }
version('3.4.5') { source sha256: '1d88d8a27b442fdde4aa06dc99e86b0bbf0b288963d8433112dd5fac798fd5ee' }
version('3.4.7') { source sha256: '23815a6d095696f7919090fdc3e2f9459b2c83d57224b2e446ce1f5f7333ef36' }
version('3.4.8') { source sha256: '53c4ddad41fbb6189f1f5ee0db57a51d54bd1f87f8755b3d68604156a35b045b' }

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
env['CFLAGS'] << ' -std=gnu99' if OhaiHelper.os_platform == 'sles'

# We need to recompile native gems on SLES 12 because precompiled gems
# such as nokogiri now require glibc >= 2.29, and SLES 12 uses an older
# version.
#
# By default, Ruby C extensions use `RbConfig::MAKEFILE_CONFIG["CC"]`,
# which is the C compiler used to build Ruby. Some C extensions can use
# alternative compilers by defining the CC/CXX environment
# variables. However, google-protobuf does not yet support this, but
# https://github.com/protocolbuffers/protobuf/pull/19863 adds upstream
# support. For now, compiling the Ruby interpreter with GCC 8 works and
# avoids the need to specify the compiler for every extension that needs
# it.
if OhaiHelper.sles12?
  env['CC'] = "/usr/bin/gcc-8"
  env['CXX'] = "/usr/bin/g++-8"
end

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

  # Two patches:
  # 1. Enable custom patch created by ayufan that allows to count memory allocations
  #    per-thread. This is asked to be upstreamed as part of https://github.com/ruby/ruby/pull/3978
  # 2. Backport Ruby upstream patch to fix seg faults in libxml2/Nokogiri: https://bugs.ruby-lang.org/issues/19580
  #    This has been merged for Ruby 3.2.3 and backported to 3.1.5.
  patches = if version.satisfies?('>= 3.2.3') || version.satisfies?(['>= 3.1.5', '< 3.2.0'])
              %w[thread-memory-allocations]
            else
              %w[thread-memory-allocations fix-ruby-xfree-for-libxml2]
            end

  # Due to https://bugs.ruby-lang.org/issues/20451, this patch is needed
  # to compile Ruby 3.1.5 on platforms with libffi < 3.2. This patch pulls in
  # https://github.com/ruby/ruby/pull/10696.
  patches += %w[fiddle-closure] if version.satisfies?('= 3.1.5')

  ruby_version = Gem::Version.new(version).canonical_segments[0..1].join('.')

  patches.each do |patch_name|
    patch source: "#{patch_name}-#{ruby_version}.patch", plevel: 1, env: env
  end

  # copy_file_range() has been disabled on recent RedHat kernels:
  # 1. https://gitlab.com/gitlab-org/gitlab/-/issues/218999
  # 2. https://bugs.ruby-lang.org/issues/16965
  # 3. https://bugzilla.redhat.com/show_bug.cgi?id=1783554
  patch source: 'ruby-disable-copy-file-range.patch', plevel: 1, env: env if version.start_with?('2.7') && (centos? || rhel?)

  # OpenSSL 3 dropped the methods FIPS_mode and FIPS_mode_set. However, Ruby
  # only dropped them in version 3.3.0 We are cherry-picking
  # https://github.com/ruby/ruby/commit/678d41bc51f.
  patch source: 'fix-ruby-fips-symbols.patch', plevel: 1, env: env if version.satisfies?('< 3.3.0')

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

  # Install OpenSSL gem for FIPS fixes
  gem "install openssl --version '#{Gitlab::Util.get_env('OPENSSL_GEM_VERSION')}' --force --no-document"

  block 'ensure default gem directories are preserved' do
    Dir["#{install_dir}/embedded/lib/ruby/gems/#{ruby_version}.0/gems/*/"].each do |dir|
      File.write(File.join(dir, '.gitkeep'), '') if File.directory?(dir)
    end
  end
end
