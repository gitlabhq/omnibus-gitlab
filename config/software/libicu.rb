#
## Copyright:: Copyright (c) 2014 GitLab.com
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
default_version "52.1"

source :url => "http://download.icu-project.org/files/icu4c/52.1/icu4c-52_1-src.tgz",
       :md5 => "9e96ed4c1d99c0d14ac03c140f9f346c"

relative_path 'icu/source'

build do
  env = with_standard_compiler_flags(with_embedded_path)
  env['LD_RPATH'] = "#{install_dir}/embedded/lib"

  command ["./runConfigureICU",
           "Linux/gcc",
           "--prefix=#{install_dir}/embedded",
           "--with-data-packaging=archive"
	   ].join(" "), :env => env

  command "make -j #{max_build_jobs}", :env => env
  command "make install"
end
