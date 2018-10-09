#
# Copyright:: Copyright (c) 2018 GitLab Inc.
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

name 'libpng'
default_version '1.6.35'

license 'Libpng'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'zlib'

source url: "https://download.sourceforge.net/libpng/libpng-#{version}.tar.gz",
       sha256: '2b82ab3e996803b80bc73206857e826a155d3ebb374e8eb03a87a63c6f672cf7'

relative_path "libpng-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  configure_command = [
    './configure',
    "--prefix=#{install_dir}/embedded",
    "--with-zlib=#{install_dir}/embedded"
  ]

  command configure_command.join(' '), env: env

  make "-j #{workers}", env: env
  make 'install', env: env
end
