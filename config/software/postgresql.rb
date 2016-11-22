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

name "postgresql"
default_version '9.2.18'

license "PostgreSQL"
license_file "COPYRIGHT"

dependency "zlib"
dependency "openssl"
dependency "libedit"
dependency "ncurses"
dependency "libossp-uuid"
dependency "config_guess"

version '9.2.18' do
  source md5: 'fd175eb5f29557c6ef2eeaf340330f9a'
end

source url: "https://ftp.postgresql.org/pub/source/v#{version}/postgresql-#{version}.tar.bz2"

relative_path "postgresql-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  prefix = "#{install_dir}/embedded/postgresql/#{version}"
  update_config_guess(target: "config")

  command "./configure" \
    " --prefix=#{prefix}" \
    " --with-libedit-preferred" \
    " --with-openssl" \
    " --with-ossp-uuid", env: env

  make "world -j #{workers}", env: env
  make "install-world", env: env

  block 'link bin files' do
    Dir.glob("#{prefix}/bin/*").each do |bin_file|
      link bin_file, "#{install_dir}/embedded/bin/#{File.basename(bin_file)}"
    end
  end
end
