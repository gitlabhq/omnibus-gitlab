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

name 'postgresql_new'
default_version '17.7'

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

version '17.7' do
  source sha256: 'ef9e343302eccd33112f1b2f0247be493cb5768313adeb558b02de8797a2e9b5'
end

major_version = '17'

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

  make "world-bin -j #{workers}", env: env
  make 'install-world-bin', env: env

  libpq = 'libpq.so.5'
  link "#{prefix}/lib/#{libpq}", "#{install_dir}/embedded/lib/#{libpq}"
end

# exclude headers and static libraries from package
project.exclude "embedded/postgresql/#{major_version}/include"
project.exclude "embedded/postgresql/#{major_version}/lib/*.a"
project.exclude "embedded/postgresql/#{major_version}/lib/pgxs"
project.exclude "embedded/postgresql/#{major_version}/lib/pkgconfig"
