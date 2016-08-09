#
## Copyright:: Copyright (c) 2014 GitLab B.V.
## License:: Apache License, Version 2.0
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

name "libicu"
default_version "56.1"

source url: "http://download.icu-project.org/files/icu4c/56.1/icu4c-56_1-src.tgz",
       sha256: "3a64e9105c734dcf631c0b3ed60404531bce6c0f5a64bfe1a6402a4cc2314816"

license "MIT"
license_file "license.html"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  env['LD_RPATH'] = "#{install_dir}/embedded/lib"
  cwd = "#{Omnibus::Config.source_dir}/libicu/icu/source"

  command ["./runConfigureICU",
           "Linux/gcc",
           "--prefix=#{install_dir}/embedded",
           "--with-data-packaging=files",
           "--enable-shared",
           "--without-samples"
     ].join(" "), env: env, cwd: cwd

  make "-j #{workers}", env: env, cwd: cwd
  make "install", env: env, cwd: cwd
end
