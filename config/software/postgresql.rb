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
default_version '13.13'

license 'PostgreSQL'
license_file 'COPYRIGHT'

skip_transitive_dependency_licensing true

dependency 'zlib'
dependency 'openssl' unless Build::Check.use_system_ssl?
dependency 'libedit'
dependency 'ncurses'
dependency 'libossp-uuid'
dependency 'config_guess'

version '13.13' do
  source sha256: '8af69c2599047a2ad246567d68ec4131aef116954d8c3e469e9789080b37a474'
end

major_version = '13'

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
