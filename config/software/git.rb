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

require "#{Omnibus::Config.project_root}/lib/gitlab/version"
version = Gitlab::Version.new('gitaly')

name 'git'

# We simply use Gitaly's version as the git version here given that Gitaly is
# the provider of git and manages the version for us.
default_version version.print

license 'GPL-2.0'
license_file 'COPYING'

vendor 'gitlab'

skip_transitive_dependency_licensing true

# Runtime dependency
dependency 'zlib'
dependency 'openssl' unless Build::Check.use_system_ssl?
dependency 'curl'
dependency 'pcre2'
dependency 'libiconv'

source git: version.remote

build do
  env = with_standard_compiler_flags(with_embedded_path)

  build_options = [
    "# Added by Omnibus git software definition git.rb",
    "GIT_BUILD_OPTIONS += CURLDIR=#{install_dir}/embedded",
    "GIT_BUILD_OPTIONS += ICONVDIR=#{install_dir}/embedded",
    "GIT_BUILD_OPTIONS += ZLIB_PATH=#{install_dir}/embedded",
    "GIT_BUILD_OPTIONS += NEEDS_LIBICONV=YesPlease",
    "GIT_BUILD_OPTIONS += USE_LIBPCRE2=YesPlease",
    "GIT_BUILD_OPTIONS += NO_PERL=YesPlease",
    "GIT_BUILD_OPTIONS += NO_EXPAT=YesPlease",
    "GIT_BUILD_OPTIONS += NO_TCLTK=YesPlease",
    "GIT_BUILD_OPTIONS += NO_GETTEXT=YesPlease",
    "GIT_BUILD_OPTIONS += NO_PYTHON=YesPlease",
    "GIT_BUILD_OPTIONS += NO_INSTALL_HARDLINKS=YesPlease",
    "GIT_BUILD_OPTIONS += NO_R_TO_GCC_LINKER=YesPlease",
    "GIT_BUILD_OPTIONS += CFLAGS=-fno-omit-frame-pointer"
  ]

  build_options << "GIT_BUILD_OPTIONS += OPENSSLDIR=#{install_dir}/embedded" unless Build::Check.use_system_ssl?

  block do
    File.open(File.join(project_dir, 'config.mak'), 'a') do |file|
      file.print build_options.join("\n")
    end
  end

  command "make git GIT_PREFIX=#{install_dir}/embedded", env: env
end
