#
# Copyright 2012-2014 Chef Software, Inc.
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

name "redis"
default_version "2.8.2"

version "2.8.2" do
  source md5: "ee527b0c37e1e2cbceb497f5f6b8112b"
end

version "2.4.7" do
  source md5: "6afffb6120724183e40f1cac324ac71c"
end

source url: "http://download.redis.io/releases/redis-#{version}.tar.gz"

relative_path "redis-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path).merge(
    "PREFIX" => "#{install_dir}/embedded",
  )

  command "make -j #{max_build_jobs}", env: env
  command "make install", env: env
end
