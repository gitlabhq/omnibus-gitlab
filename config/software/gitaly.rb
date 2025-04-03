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

  # SLES uses gcc v4.8.5 with C90 (`-std=gnu90`) by default.
  # C11 is a newer standard than C90, and gcc v5.1.0 switched the default
  # from `std=gnu90` to `std=gnu11`.
  # Git v2.35 added a balloon test that will fail the build if
  # C99 is not supported. On other platforms, C11 may be required
  # (https://gitlab.com/gitlab-org/gitlab-git/-/commit/7bc341e21b5).
  git_cflags += ' -std=gnu99' if OhaiHelper.os_platform == 'sles'

  git_append_build_options = [
    "# Added by Omnibus git software definition gitaly.rb",
    "GIT_APPEND_BUILD_OPTIONS += CURLDIR=#{install_dir}/embedded",
    "GIT_APPEND_BUILD_OPTIONS += ICONVDIR=#{install_dir}/embedded",
    "GIT_APPEND_BUILD_OPTIONS += ZLIB_PATH=#{install_dir}/embedded",
    "GIT_APPEND_BUILD_OPTIONS += NEEDS_LIBICONV=YesPlease",
    "GIT_APPEND_BUILD_OPTIONS += NO_R_TO_GCC_LINKER=YesPlease",
    "GIT_APPEND_BUILD_OPTIONS += INSTALL_SYMLINKS=YesPlease",
    # The 'single quotes' around the CFLAGS value is important, as Make doesn't
    # seem to parse this correctly with "double quotes".
    "GIT_APPEND_BUILD_OPTIONS += CFLAGS=\'#{git_cflags}\'",
    # Gitaly compiles Git with build type "debugoptimized" by default, which
    # includes debug symbols. We don't want them in order to reduce package
    # size, so we override the build type to "release" instead.
    "GIT_APPEND_MESON_BUILD_OPTIONS += -Dbuildtype=release"
  ]

  use_meson = Gitlab::Util.get_env('GITALY_USE_MESON') || 'true'
  if use_meson == 'true'
    # Use Meson to build Git. This only impacts Git v2.48.0 and newer, older
    # version will still be built with the old and venerable Makefile. Once
    # Gitaly has deprecated support for older versions we can drop the infra
    # for Makefiles.
    #
    # Note that with Meson, we don't have to manually configure all dependency
    # locations anymore. Instead, those dependencies will now be picked up via
    # the PKG_CONFIG_PATH.
    git_append_build_options << "USE_MESON=YesPlease"
  end

  if Build::Check.use_system_ssl?
    env['CMAKE_FLAGS'] = OpenSSLHelper.cmake_flags
    env['FIPS_MODE'] = '1'

    pkg_config_overrides = File.join(project_dir, 'pkg-config-overrides')
    mkdir pkg_config_overrides
    OpenSSLHelper.pkg_config_files.each_value do |file|
      copy file, pkg_config_overrides
    end
    env['PKG_CONFIG_PATH'] = "#{pkg_config_overrides}:#{install_dir}/embedded/lib/pkgconfig"
  else
    git_append_build_options << "GIT_APPEND_BUILD_OPTIONS += OPENSSLDIR=#{install_dir}/embedded"
    env['PKG_CONFIG_PATH'] = "#{install_dir}/embedded/lib/pkgconfig"
  end

  # Gitaly's Makefile will include config.mak, which expands GITALY_APPEND_BUILD_OPTIONS
  # and passes the options to Git's Makefile when Git is compiled.
  block do
    File.open(File.join(project_dir, 'config.mak'), 'a') do |file|
      file.print git_append_build_options.join("\n")
    end
  end

  make "install PREFIX=#{install_dir}/embedded", env: env

  command "license_finder report --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=json --columns name version licenses texts notice --save=licenses.json"
  copy "licenses.json", "#{install_dir}/licenses/gitaly.json"
end
