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
default_version '2.24.2'

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
       sha256: '159fe7ee7532e9a2828bef51dc528210fc3607c3aa713cd12bc5c4f26fddbdd1'

relative_path "git-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # Patch series to Rewrite packfile reuse code
  #
  # See https://github.com/chriscool/git/commits/gh-pack-reuse44
  # And https://public-inbox.org/git/20191218112547.4974-1-chriscool@tuxfamily.org/
  #
  # Hopefully the patch series will be merged into Git v2.26.0 and these patches
  # won't be needed anymore.

  patch source: 'v4-0001-builtin-pack-objects-report-reused-packfile-objec.patch'
  patch source: 'v4-0002-packfile-expose-get_delta_base.patch'
  patch source: 'v4-0003-ewah-bitmap-introduce-bitmap_word_alloc.patch'
  patch source: 'v4-0004-pack-bitmap-introduce-bitmap_walk_contains.patch'
  patch source: 'v4-0005-pack-bitmap-uninteresting-oid-can-be-outside-bitm.patch'
  patch source: 'v4-0006-pack-bitmap-simplify-bitmap_has_oid_in_uninterest.patch'
  patch source: 'v4-0007-csum-file-introduce-hashfile_total.patch'
  patch source: 'v4-0008-pack-objects-introduce-pack.allowPackReuse.patch'
  patch source: 'v4-0009-builtin-pack-objects-introduce-obj_is_packed.patch'
  patch source: 'v4-0010-pack-objects-improve-partial-packfile-reuse.patch'
  patch source: 'v4-0011-pack-objects-add-checks-for-duplicate-objects.patch'
  patch source: 'v4-0012-pack-bitmap-don-t-rely-on-bitmap_git-reuse_object.patch'

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
      EOH
    end
  end

  command "make -j #{workers} prefix=#{install_dir}/embedded", env: env
  command "make install prefix=#{install_dir}/embedded", env: env
end
