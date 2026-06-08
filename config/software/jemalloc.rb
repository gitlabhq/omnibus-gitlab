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
version = Gitlab::Version.new('jemalloc', '5.3.1')
default_version version.print(false)

license 'jemalloc'
license_file 'COPYING'

skip_transitive_dependency_licensing true

# Ensure redis and valkey are compiled first so they can build their own jemalloc
dependency 'redis'
dependency 'valkey'

if Build::Check.use_ubt? && !Build::Check.use_system_ssl?
  source Build::UBT.source_args(name, "#{default_version}-1ubt", "e09474a4899a11b73ace65ba807b3dac154c090e695ec9af4295bb2ae53fa1de", OhaiHelper.arch)
  build(&Build::UBT.install)
else
  source git: version.remote

  env = with_standard_compiler_flags(with_embedded_path)

  relative_path "jemalloc-#{version.print}"

  build do
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
end

project.exclude "embedded/bin/jemalloc-config"
