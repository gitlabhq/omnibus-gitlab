#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

name 'libevent'
default_version '2.1.8'

license 'BSD-3-Clause'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

version '2.1.8' do
  source sha256: '965cc5a8bb46ce4199a47e9b2c9e1cae3b137e8356ffdad6d94d3b9069b71dc2'
end

source url: "https://github.com/libevent/libevent/releases/download/release-#{version}-stable/libevent-#{version}-stable.tar.gz"

relative_path "libevent-#{version}-stable"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  command './configure ' \
    "--prefix=#{install_dir}/embedded", env: env

  make "-j #{workers}", env: env
  make 'install', env: env
end
