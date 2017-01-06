#
# Copyright 2014 Chef Software, Inc.
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

name "expat"
default_version "2.1.0"

relative_path "expat-#{version}"
dependency "config_guess"

license "MIT"
license_file "COPYING"
skip_transitive_dependency_licensing true

source url: "http://downloads.sourceforge.net/project/expat/expat/#{version}/expat-#{version}.tar.gz",
       md5: "dd7dab7a5fea97d2a6a43f511449b7cd"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  update_config_guess(target: "conftools")

  command "./configure" \
          " --prefix=#{install_dir}/embedded", env: env

  make "-j #{workers}", env: env
  make "install", env: env
end
