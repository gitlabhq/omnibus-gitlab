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

if Build::Check.use_ubt? && !Build::Check.use_system_ssl?
  # NOTE: We cannot use UBT binaries in FIPS builds
  # TODO: We're using OhaiHelper to detect current platform, however since components are pre-compiled by UBT we *may* run ARM build on X86 nodes
  # FIXME: version has drifted in Omnibus vs UBT builds
  source Build::UBT.source_args(name, "5.3.0", "d21240f054c5d115c79a8158040525a14739e72d5c188bfc9ef1d1df38410abc", OhaiHelper.arch)
  build(&Build::UBT.install)
else
  source git: version.remote

  # Ensure redis and valkey are compiled first so they can build their own jemalloc
  dependency 'redis'
  dependency 'valkey'

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
