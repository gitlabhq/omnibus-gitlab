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

source :url => "http://download.icu-project.org/files/icu4c/56.1/icu4c-56_1-src.tgz",
       :md5 => "c4a2d71ff56aec5ebfab2a3f059be99d"

relative_path 'icu/source'

license "MIT"
license_file "license.html"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  env['LD_RPATH'] = "#{install_dir}/embedded/lib"

  command ["./runConfigureICU",
           "Linux/gcc",
           "--prefix=#{install_dir}/embedded",
           "--with-data-packaging=files",
           "--enable-shared",
           "--without-samples"
     ].join(" "), :env => env

  command "make -j #{workers}", :env => env
  command "make install"
end
