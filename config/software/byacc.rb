#
# Copyright:: Copyright (c) 2014 GitLab B.V.
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

name "byacc"

default_version '20141128'

source url: "http://invisible-island.net/datafiles/release/byacc.tar.gz",
       md5: 'acb0ff0fb6cc414a6b50c799794b2425'

relative_path 'byacc'

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # byacc.tar.gz will contain current date at the time of the build
  # eg. byacc-20141128
  # move it to a known name for consitency
  command "mv byacc-* byacc", cwd: source_dir

  command "./configure" \
          " --prefix=#{install_dir}/embedded", env: env

  command "make -j #{max_build_jobs}", :env => env
  command "make install"
end
