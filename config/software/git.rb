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

name 'git'

# When updating the git version here, but sure to also update the following:
# - https://gitlab.com/gitlab-org/gitaly/blob/master/README.md#installation
# - https://gitlab.com/gitlab-org/gitaly/blob/master/.gitlab-ci.yml
# - https://gitlab.com/gitlab-org/gitlab-foss/blob/master/doc/install/installation.md
# - https://gitlab.com/gitlab-org/gitlab-recipes/blob/master/install/centos/README.md
# - https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/prepare.md
# - https://gitlab.com/gitlab-org/gitlab-build-images/blob/master/.gitlab-ci.yml
# - https://gitlab.com/gitlab-org/gitlab-foss/blob/master/.gitlab-ci.yml
# - https://gitlab.com/gitlab-org/gitlab-foss/blob/master/lib/system_check/app/git_version_check.rb
# - https://gitlab.com/gitlab-org/build/CNG/blob/master/ci_files/variables.yml
default_version '2.27.0'

license 'GPL-2.0'
license_file 'COPYING'

skip_transitive_dependency_licensing true

# Runtime dependency
dependency 'zlib'
dependency 'openssl'
dependency 'curl'
dependency 'pcre2'
dependency 'libiconv'

source url: "https://www.kernel.org/pub/software/scm/git/git-#{version}.tar.gz",
       sha256: '77ded85cbe42b1ffdc2578b460a1ef5d23bcbc6683eabcafbb0d394dffe2e787'

relative_path "git-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # Optionally add patches to apply to Git sources here, like this:
  #
  # patch source: 'v4-0001-builtin-pack-objects-report-reused-packfile-objec.patch'
  # patch source: 'v4-0002-packfile-expose-get_delta_base.patch'
  #
  # Patch files should be in config/patches/git/

  block do
    File.open(File.join(project_dir, 'config.mak'), 'a') do |file|
      file.print <<-EOH
# Added by Omnibus git software definition git.rb
CURLDIR=#{install_dir}/embedded
ICONVDIR=#{install_dir}/embedded
OPENSSLDIR=#{install_dir}/embedded
ZLIB_PATH=#{install_dir}/embedded
NEEDS_LIBICONV=YesPlease
USE_LIBPCRE2=YesPlease
NO_PERL=YesPlease
NO_EXPAT=YesPlease
NO_TCLTK=YesPlease
NO_GETTEXT=YesPlease
NO_PYTHON=YesPlease
NO_INSTALL_HARDLINKS=YesPlease
NO_R_TO_GCC_LINKER=YesPlease
CFLAGS=-fno-omit-frame-pointer
      EOH
    end
  end

  command "make -j #{workers} prefix=#{install_dir}/embedded", env: env
  command "make install prefix=#{install_dir}/embedded", env: env
end
