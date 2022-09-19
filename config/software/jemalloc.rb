#
# Copyright:: Copyright (c) 2016 GitLab Inc.
# License:: Apache License, Version 2.0
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

name 'jemalloc'
version = Gitlab::Version.new('jemalloc', '5.3.0')
default_version version.print(false)

license 'jemalloc'
license_file 'COPYING'

skip_transitive_dependency_licensing true

source git: version.remote

# Ensure redis is compiled first so it can build its own jemalloc
dependency 'redis'

env = with_standard_compiler_flags(with_embedded_path)

relative_path "jemalloc-#{version}"

build do
  # CentOS 6 doesn't have a new enough version of autoconf so we have to
  # use the one packaged in EPEL
  if ohai['platform'] =~ /centos/ && ohai['platform_version'] =~ /^6/
    command 'sed -i -e s:autoconf:autoconf268: autogen.sh', env: env
    env['AUTOCONF'] = '/usr/bin/autoconf268'
  end

  autogen_command = [
    './autogen.sh',
    '--enable-prof',
    "--prefix=#{install_dir}/embedded"
  ]

  # jemallocs page size must be >= to the runtime pagesize
  # Use large for arm/newer platforms based on debian rules:
  # https://salsa.debian.org/debian/jemalloc/-/blob/c0a88c37a551be7d12e4863435365c9a6a51525f/debian/rules#L8-23
  autogen_command << (OhaiHelper.arm64? ? '--with-lg-page=16' : '--with-lg-page=12')

  command autogen_command.join(' '), env: env
  make "-j #{workers} install", env: env
end

project.exclude "embedded/bin/jemalloc-config"
