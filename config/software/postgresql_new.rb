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
default_version '14.11'

license 'PostgreSQL'
license_file 'COPYRIGHT'

skip_transitive_dependency_licensing true

dependency 'zlib'
dependency 'openssl' unless Build::Check.use_system_ssl?
dependency 'libedit'
dependency 'ncurses'
dependency 'libossp-uuid'
dependency 'config_guess'

version '14.11' do
  source sha256: 'a670bd7dce22dcad4297b261136b3b1d4a09a6f541719562aa14ca63bf2968a8'
end

major_version = '14'
libpq = 'libpq.so.5'

source url: "https://ftp.postgresql.org/pub/source/v#{version}/postgresql-#{version}.tar.bz2"

relative_path "postgresql-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  env['CFLAGS'] << ' -fno-omit-frame-pointer'

  prefix = "#{install_dir}/embedded/postgresql/#{major_version}"
  update_config_guess(target: 'config')

  patch source: 'no_docs.patch', target: 'GNUmakefile.in'

  command './configure' \
          " --prefix=#{prefix}" \
          ' --with-libedit-preferred' \
          ' --with-openssl' \
          ' --with-uuid=ossp', env: env

  make "world -j #{workers}", env: env
  make 'install-world', env: env

  link "#{prefix}/lib/#{libpq}", "#{install_dir}/embedded/lib/#{libpq}"

  # NOTE: There are several dependencies which require these files in these
  # locations and have dependency on `postgresql_new`. So when this block is
  # changed to be in the `postgresql` software definition for default PG
  # version changes, change those dependencies to `postgresql`.
  block 'link bin files' do
    Dir.glob("#{prefix}/bin/*").each do |bin_file|
      link bin_file, "#{install_dir}/embedded/bin/#{File.basename(bin_file)}"
    end
  end
end

# exclude headers and static libraries from package
project.exclude "embedded/postgresql/#{major_version}/include"
project.exclude "embedded/postgresql/#{major_version}/lib/*.a"
project.exclude "embedded/postgresql/#{major_version}/lib/pgxs"
project.exclude "embedded/postgresql/#{major_version}/lib/pkgconfig"
