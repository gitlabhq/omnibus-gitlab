#
# Copyright 2013-2014 Chef Software, Inc.
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

name "nodejs"
default_version "0.10.10"

dependency "python"

version "0.10.10" do
  source md5: "a47a9141567dd591eec486db05b09e1c"
end

version "0.10.26" do
  source md5: "15e9018dadc63a2046f61eb13dfd7bd6"
end

version "0.10.35" do
  source md5: "2c00d8cf243753996eecdc4f6e2a2d11"
end

source url: "https://nodejs.org/dist/v#{version}/node-v#{version}.tar.gz"

relative_path "node-v#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  command "#{install_dir}/embedded/bin/python ./configure" \
          " --prefix=#{install_dir}/embedded", env: env

  make "-j #{workers}", env: env
  make "install", env: env
end
