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

name "postgresql_new"
default_version "9.6.1"

license "PostgreSQL"
license_file "COPYRIGHT"

dependency "zlib"
dependency "openssl"
dependency "libedit"
dependency "ncurses"
dependency "libossp-uuid"
dependency "config_guess"

version "9.6.0" do
  source md5: "c5af6ebb790ab877e1d2e56e19cebb29"
end

version '9.6.1' do
  source sha256: 'e5101e0a49141fc12a7018c6dad594694d3a3325f5ab71e93e0e51bd94e51fcd'
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
end
