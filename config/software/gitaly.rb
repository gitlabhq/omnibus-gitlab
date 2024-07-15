#
# Copyright:: Copyright (c) 2017-2022 GitLab Inc.
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

require "#{Omnibus::Config.project_root}/lib/gitlab/version"
require "#{Omnibus::Config.project_root}/lib/gitlab/ohai_helper.rb"
version = Gitlab::Version.new('gitaly')

name 'gitaly'
default_version version.print

license 'MIT'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'pkg-config-lite'
dependency 'ruby'
dependency 'libicu'
dependency 'omnibus-gitlab-gems'

# Dependencies for building Git as part of Gitaly
dependency 'zlib'
dependency 'openssl' unless Build::Check.use_system_ssl?
dependency 'curl'
dependency 'pcre2'
dependency 'libiconv'

# Technically, gitaly depends on git also. But because of how omnibus arranges
# components to be built, this causes git to be built early in the process. But
# in our case, git is built from gitaly source code. This results in git
# invalidating the cache frequently as Gitaly's master branch is a fast moving
# target. So, we are kinda cheating here and depending on the presence of git
# in the project's direct dependency list before gitaly as a workaround.
# The conditional will ensure git gets built before gitaly in scenarios where
# the entire GitLab project is not built, but only a subset of it is.

dependency 'git' unless project.dependencies.include?('git')

source git: version.remote

build do
  env = with_standard_compiler_flags(with_embedded_path)

  git_cflags = '-fno-omit-frame-pointer'

  # CentOS 7 uses gcc v4.8.5, which uses C90 (`-std=gnu90`) by default.
  # C11 is a newer standard than C90, and gcc v5.1.0 switched the default
  # from `std=gnu90` to `std=gnu11`.
  # Git v2.35 added a balloon test that will fail the build if
  # C99 is not supported. On other platforms, C11 may be required
  # (https://gitlab.com/gitlab-org/gitlab-git/-/commit/7bc341e21b5).
  # Similar is the case for SLES OSs also.
  git_cflags += ' -std=gnu99' if OhaiHelper.get_centos_version.to_i == 7 || OhaiHelper.os_platform == 'sles'

  env['CURLDIR'] = "#{install_dir}/embedded"
  env['ICONVDIR'] = "#{install_dir}/embedded"
  env['ZLIB_PATH'] = "#{install_dir}/embedded"
  env['NEEDS_LIBICONV'] = 'YesPlease'
  env['NO_R_TO_GCC_LINKER'] = 'YesPlease'
  env['INSTALL_SYMLINKS'] = 'YesPlease'
  env['CFLAGS'] = "\"#{git_cflags}\""

  if Build::Check.use_system_ssl?
    env['CMAKE_FLAGS'] = OpenSSLHelper.cmake_flags
    env['PKG_CONFIG_PATH'] = OpenSSLHelper.pkg_config_dirs
    env['FIPS_MODE'] = '1'
  else
    env['OPENSSLDIR'] = "#{install_dir}/embedded"
  end

  make "install PREFIX=#{install_dir}/embedded", env: env

  command "license_finder report --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=json --columns name version licenses texts notice --save=licenses.json"
  copy "licenses.json", "#{install_dir}/licenses/gitaly.json"
end
