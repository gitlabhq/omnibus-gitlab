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

name 'repmgr'
default_version '3.3.1'

license 'gplv3'
license_file 'LICENSE'

source url: "http://www.repmgr.org/download/repmgr-#{version}.tar.gz",
       sha1: '54860f53f53ef1fd2a1353d1f7153df3beb1e2f6'

dependency 'postgresql_new'

env = with_standard_compiler_flags(with_embedded_path)

relative_path "#{name}-#{version}"

build do
  make "-j #{workers} USE_PGXS=1 install", env: env

  block 'link bin files' do
    %w(repmgr repmgrd).each do |bin_file|
      link "#{install_dir}/embedded/postgresql/9.6.3/bin/#{bin_file}", "#{install_dir}/embedded/bin/#{bin_file}"
    end
  end
end
