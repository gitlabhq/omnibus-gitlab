#
## Copyright:: Copyright (c) 2014 GitLab Inc.
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
require "#{Omnibus::Config.project_root}/lib/gitlab/ohai_helper.rb"
require "#{Omnibus::Config.project_root}/lib/gitlab/build/info/components"
version = Gitlab::Version.new('gitaly')

name 'git'

# We simply use Gitaly's version as the git version here given that Gitaly is
# the provider of git and manages the version for us.
default_version version.print

license 'GPL-2.0'
license_file '_build/deps/git/source/COPYING'

vendor 'gitlab'

skip_transitive_dependency_licensing true

# Runtime dependency
dependency 'zlib-ng'
dependency 'openssl' unless Build::Check.use_system_ssl?
dependency 'curl'
dependency 'pcre2'
dependency 'libiconv'

source git: version.remote

build do
  env = with_standard_compiler_flags(with_embedded_path)

  git_cflags = '-fno-omit-frame-pointer'

  # SLES uses gcc with C90 (`-std=gnu90`) by default.
  # C11 is a newer standard than C90, and gcc v5.1.0 switched the default
  # from `std=gnu90` to `std=gnu11`.
  # Git v2.35 added a balloon test that will fail the build if
  # C99 is not supported. On other platforms, C11 may be required
  # (https://gitlab.com/gitlab-org/gitlab-git/-/commit/7bc341e21b5).
  git_cflags += ' -std=gnu99' if OhaiHelper.os_platform == 'sles'

  # NOTE: the Git software definition is in the process of being deprecated in favour of bundling
  # Git with Gitaly. Any changes to the following build options must be replicated to the Gitaly
  # software definition at config/software/gitaly.rb in git_append_build_options. See
  # https://gitlab.com/gitlab-org/gitaly/-/issues/6195 for more information.
  build_options = [
    "# Added by Omnibus git software definition git.rb",
    "GIT_APPEND_BUILD_OPTIONS += CURLDIR=#{install_dir}/embedded",
    "GIT_APPEND_BUILD_OPTIONS += ICONVDIR=#{install_dir}/embedded",
    "GIT_APPEND_BUILD_OPTIONS += ZLIB_PATH=#{install_dir}/embedded",
    "GIT_APPEND_BUILD_OPTIONS += NEEDS_LIBICONV=YesPlease",
    "GIT_APPEND_BUILD_OPTIONS += NO_R_TO_GCC_LINKER=YesPlease",
    "GIT_APPEND_BUILD_OPTIONS += INSTALL_SYMLINKS=YesPlease",
    "GIT_APPEND_BUILD_OPTIONS += CFLAGS=\"#{git_cflags}\"",
    # Gitaly compiles Git with build type "debugoptimized" by default, which
    # includes debug symbols. We don't want them in order to reduce package
    # size, so we override the build type to "release" instead.
    "GIT_APPEND_MESON_BUILD_OPTIONS += -Dbuildtype=release",
    "GIT_APPEND_MESON_BUILD_OPTIONS += --native-file=#{File.join(project_dir, 'meson.ini')}"
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
    build_options << "USE_MESON=YesPlease"
    env['CFLAGS'] << ' -fno-omit-frame-pointer'
  end

  if Build::Check.use_system_ssl?
    env['FIPS_MODE'] = '1'

    pkg_config_overrides = File.join(project_dir, 'pkg-config-overrides')
    mkdir pkg_config_overrides
    OpenSSLHelper.pkg_config_files.each_pair do |file_name, file_path|
      copy file_path, pkg_config_overrides
      # Don't laugh, it works.  No matter what AmazonLinux 2 asks for - tell it that it wants OpenSSL 1.1 or bust.
      copy file_path, File.join(pkg_config_overrides, file_name.gsub(/11.pc$/, '.pc')) if OhaiHelper.amazon_linux_2?
    end
    env['PKG_CONFIG_PATH'] = "#{pkg_config_overrides}:#{install_dir}/embedded/lib/pkgconfig"
  else
    build_options << "GIT_APPEND_BUILD_OPTIONS += OPENSSLDIR=#{install_dir}/embedded"
    env['PKG_CONFIG_PATH'] = "#{install_dir}/embedded/lib/pkgconfig"
  end

  sm_version_override_git_repo_url = Gitlab::Util.get_env('SELF_MANAGED_VERSION_REGEX_OVERRIDE_GIT_REPO_URL')
  git_repo_url = Gitlab::Util.get_env('GITALY_GIT_REPO_URL')
  if Build::Check.is_auto_deploy_tag?
    # Gitaly potentially bundles multiple different Git distributions with it.
    # It is possible to override the specific version that Gitaly compiles each
    # of these distributions with by setting:
    #
    #     `GIT_VERSION_2_38=v2.38.1`
    #
    # As the bundled Git versions change over time we have this generic loop to
    # just accept any such override into the environment used by make.
    ENV.select { |k, v| k.start_with?('GITALY_GIT_VERSION_') }.each do |k, v|
      env[k.delete_prefix('GITALY_')] = v unless v&.empty?
    end

    env['GIT_REPO_URL'] = git_repo_url if git_repo_url
  elsif sm_version_override_git_repo_url && Regexp.new(sm_version_override_git_repo_url).match?(Build::Info::Components::GitLabRails.version)
    env['GIT_REPO_URL'] = git_repo_url if git_repo_url
  end

  block do
    File.open(File.join(project_dir, 'config.mak'), 'a') do |file|
      file.print build_options.join("\n")
    end

    File.open(File.join(project_dir, 'meson.ini'), 'a') do |file|
      file.print <<-EOS
        [binaries]
        sh = '/bin/sh'
      EOS
    end
  end

  # For now we install both a Git distribution as well as bundled Git. This is
  # only done temporarily to migrate to bundled Git via a feature flagged
  # rollout. Eventually, we will only install bundled Git.
  command "make git install-bundled-git PREFIX=#{install_dir}/embedded GIT_PREFIX=#{install_dir}/embedded", env: env
end
