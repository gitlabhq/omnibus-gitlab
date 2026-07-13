#
# Copyright 2012-2014 Chef Software, Inc.
# Copyright:: Copyright (c) 2016 GitLab Inc.
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

name 'postgresql'
default_version '16.14'
major_version = default_version.split('.')[0]

license 'PostgreSQL'
license_file 'COPYRIGHT'

skip_transitive_dependency_licensing true

dependency 'zlib-ng'
dependency 'openssl' unless Build::Check.use_system_ssl?
dependency 'libedit'
dependency 'libicu'
dependency 'ncurses'
dependency 'libossp-uuid'
dependency 'config_guess'

if Build::Check.use_ubt? && !Build::Check.use_system_ssl?
  # TODO: We're using OhaiHelper to detect current platform, however since components are pre-compiled by UBT we *may* run ARM build on X86 nodes
  source Build::UBT.source_args("postgresql-all", "#{default_version}-6ubt", "55367169449b17347013962513ad28f4c981db4b555deaffc21e7eff2a044c0f", OhaiHelper.arch)
  build(&Build::UBT.install)
else
  version default_version do
    source sha256: 'f6d077142737920858ce958ccdb75c6ee137a63b5b0853c70693d401ac7e3471'
  end

  source url: "https://ftp.postgresql.org/pub/source/v#{version}/postgresql-#{version}.tar.bz2"

  relative_path "postgresql-#{version}"

  build do
    env = with_standard_compiler_flags(with_embedded_path)

    env['CFLAGS'] << ' -fno-omit-frame-pointer'

    prefix = "#{install_dir}/embedded/postgresql/#{major_version}"
    update_config_guess(target: 'config')

    command './configure' \
            " --prefix=#{prefix}" \
            ' --with-libedit-preferred' \
            ' --with-openssl' \
            ' --with-uuid=ossp', env: env

    make "world -j #{workers}", env: env
    make 'install-world-bin', env: env
  end
end

# exclude headers and static libraries from package
project.exclude "embedded/postgresql/#{major_version}/include"
project.exclude "embedded/postgresql/#{major_version}/lib/*.a"
project.exclude "embedded/postgresql/#{major_version}/lib/pgxs"
project.exclude "embedded/postgresql/#{major_version}/lib/pkgconfig"
