#
# Copyright:: Copyright (c) 2014 GitLab Inc.
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

name 'krb5'

version = Gitlab::Version.new('krb5', 'krb5-1.22.1-final')
default_version version.print(false)
display_version version.print(false).delete_prefix('krb5-').delete_suffix('-final')

license 'MIT'
license_file 'NOTICE'

skip_transitive_dependency_licensing true

dependency 'openssl' unless Build::Check.use_system_ssl?

if Build::Check.use_ubt? && !Build::Check.use_system_ssl?
  # NOTE: We cannot use UBT binaries in FIPS builds
  # TODO: We're using OhaiHelper to detect current platform, however since components are pre-compiled by UBT we *may* run ARM build on X86 nodes
  # FIXME: version has drifted in Omnibus vs UBT builds
  source Build::UBT.source_args(name, "1.22.1", "f30a3182082de1e7114b1f226f8c1006a4747b32af9070857ef5ab674e95929d", OhaiHelper.arch)
  build(&Build::UBT.install)
else
  source git: version.remote

  build do
    env = with_standard_compiler_flags(with_embedded_path)
    cwd = "#{Omnibus::Config.source_dir}/krb5/src"

    command "autoreconf", env: env, cwd: cwd
    command './configure' \
           " --prefix=#{install_dir}/embedded --without-system-verto --without-keyutils --disable-pkinit", env: env, cwd: cwd

    make " -j #{workers}", env: env, cwd: cwd
    make 'install', env: env, cwd: cwd
  end
end

project.exclude "embedded/bin/krb5-config"
