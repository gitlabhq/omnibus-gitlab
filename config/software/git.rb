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

name "git"
default_version "2.4.3"

dependency "zlib"
dependency "openssl"
dependency "curl"

source :url => "https://www.kernel.org/pub/software/scm/git/git-#{version}.tar.gz",
       :md5 => "bde9fc7aa40560fe3b1c8b9c6d170db0"

relative_path "git-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  command ["./configure",
           "--prefix=#{install_dir}/embedded",
           "--with-curl=#{install_dir}/embedded",
           "--with-ssl=#{install_dir}/embedded",
           "--with-zlib=#{install_dir}/embedded"].join(" "), :env => env

  # Ugly hack because ./configure does not pick these up from the env
  block do
    open(File.join(project_dir, "config.mak.autogen"), "a") do |file|
      file.print <<-EOH
# Added by Omnibus git software definition git.rb
NO_PERL=YesPlease
NO_EXPAT=YesPlease
NO_TCLTK=YesPlease
NO_GETTEXT=YesPlease
NO_PYTHON=YesPlease
      EOH
    end
  end

  command "make -j #{workers}", :env => env
  command "make install"
end
