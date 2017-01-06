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

license "BSD-3-Clause"
license_file "COPYING"

dependency "config_guess"
default_version "3.0.4"

version "3.0.7" do
  source md5: "84ed3f486e7a6f0ebada6917370f3532"
end

version "3.0.4" do
  source md5: "9e535dea3dc5301de012047bf3cca952"
end

version "2.8.21" do
  source md5: "d059e2bf5315e2488ab679e09e55a9e7"
end

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
    "PREFIX" => "#{install_dir}/embedded"
  )

  update_config_guess

  make "-j #{workers}", env: env
  make "install", env: env
end
