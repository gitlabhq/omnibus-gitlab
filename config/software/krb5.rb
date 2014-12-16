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

name "krb5"

default_version "1.13"

source url: "http://web.mit.edu/kerberos/dist/krb5/1.13/krb5-1.13-signed.tar",

build do
  env = with_standard_compiler_flags(with_embedded_path)

  command "tar xf krb5-1.13.tar.gz"
  command "cd krb5-1.13"

  command "./configure" \
          " --prefix=#{install_dir}/embedded", env: env

  command "make -j #{max_build_jobs}", :env => env
  command "make install"
end
