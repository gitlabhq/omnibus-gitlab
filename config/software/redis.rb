#
# Copyright 2012-2014 Chef Software, Inc.
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
require "#{Omnibus::Config.project_root}/lib/gitlab/ohai_helper.rb"

name 'redis'

license 'BSD-3-Clause'
license_file 'COPYING'

skip_transitive_dependency_licensing true

dependency 'config_guess'
dependency 'openssl' unless Build::Check.use_system_ssl?

version = Gitlab::Version.new('redis', '7.2.10')
default_version version.print(false)

source git: version.remote

# libatomic is a runtime_dependency of redis for armhf/aarch64 platforms
if OhaiHelper.arm?
  whitelist_file "#{install_dir}/embedded/bin/redis-benchmark"
  whitelist_file "#{install_dir}/embedded/bin/redis-check-aof"
  whitelist_file "#{install_dir}/embedded/bin/redis-check-rdb"
  whitelist_file "#{install_dir}/embedded/bin/redis-cli"
  whitelist_file "#{install_dir}/embedded/bin/redis-server"
end

build do
  env = with_standard_compiler_flags(with_embedded_path).merge(
    'PREFIX' => "#{install_dir}/embedded"
  )

  env['CFLAGS'] << ' -fno-omit-frame-pointer'
  env['LDFLAGS'] << ' -latomic' if OhaiHelper.raspberry_pi?

  # jemallocs page size must be >= to the runtime pagesize
  # Use large for arm/newer platforms based on debian rules:
  # https://salsa.debian.org/debian/jemalloc/-/blob/241fec81556098d6840e3684d2b4b69fea9258ef/debian/rules#L8-23
  env['JEMALLOC_CONFIGURE_OPTS'] = (OhaiHelper.arm64? ? ' --with-lg-page=16' : ' --with-lg-page=12')

  update_config_guess

  make_args = ['BUILD_TLS=yes']
  make_args << 'uname_M=armv6l' if OhaiHelper.raspberry_pi?
  make "-j #{workers} #{make_args.join(' ')}", env: env
  make 'install', env: env
end
