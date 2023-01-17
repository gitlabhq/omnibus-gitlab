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
require "#{Omnibus::Config.project_root}/lib/gitlab/ohai_helper.rb"
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
dependency 'zlib'
dependency 'openssl' unless Build::Check.use_system_ssl?
dependency 'curl'
dependency 'pcre2'
dependency 'libiconv'

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

  build_options = [
    "# Added by Omnibus git software definition git.rb",
    "GIT_APPEND_BUILD_OPTIONS += CURLDIR=#{install_dir}/embedded",
    "GIT_APPEND_BUILD_OPTIONS += ICONVDIR=#{install_dir}/embedded",
    "GIT_APPEND_BUILD_OPTIONS += ZLIB_PATH=#{install_dir}/embedded",
    "GIT_APPEND_BUILD_OPTIONS += NEEDS_LIBICONV=YesPlease",
    "GIT_APPEND_BUILD_OPTIONS += NO_R_TO_GCC_LINKER=YesPlease",
    "GIT_APPEND_BUILD_OPTIONS += INSTALL_SYMLINKS=YesPlease",
    "GIT_APPEND_BUILD_OPTIONS += CFLAGS=\"#{git_cflags}\""
  ]

  if Build::Check.use_system_ssl?
    env['FIPS_MODE'] = '1'
  else
    build_options << "GIT_APPEND_BUILD_OPTIONS += OPENSSLDIR=#{install_dir}/embedded"
  end

  sm_version_override_git_repo_url = Gitlab::Util.get_env('SELF_MANAGED_VERSION_REGEX_OVERRIDE_GIT_REPO_URL')
  git_repo_url = Gitlab::Util.get_env('GITALY_GIT_REPO_URL')
  if Build::Check.is_auto_deploy_tag?
    git_version_2_37_1 = Gitlab::Util.get_env('GITALY_GIT_VERSION_2_37_1')
    git_version_2_38 = Gitlab::Util.get_env('GITALY_GIT_VERSION_2_38')

    env['GIT_REPO_URL'] = git_repo_url if git_repo_url
    env['GIT_VERSION_2_37_1'] = git_version_2_37_1 if git_version_2_37_1
    env['GIT_VERSION_2_38'] = git_version_2_38 if git_version_2_38

  elsif sm_version_override_git_repo_url && Regexp.new(sm_version_override_git_repo_url).match?(Build::Info.gitlab_version)
    env['GIT_REPO_URL'] = git_repo_url if git_repo_url
  end

  block do
    File.open(File.join(project_dir, 'config.mak'), 'a') do |file|
      file.print build_options.join("\n")
    end
  end

  # For now we install both a Git distribution as well as bundled Git. This is
  # only done temporarily to migrate to bundled Git via a feature flagged
  # rollout. Eventually, we will only install bundled Git.
  command "make git install-bundled-git PREFIX=#{install_dir}/embedded GIT_PREFIX=#{install_dir}/embedded", env: env
end
