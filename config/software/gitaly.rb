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
dependency 'bundler'
dependency 'libicu'

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

  ruby_build_dir = "#{Omnibus::Config.source_dir}/gitaly/ruby"
  bundle_without = %w(development test)

  if Build::Check.use_system_ssl?
    env['CMAKE_FLAGS'] = OpenSSLHelper.cmake_flags
    env['PKG_CONFIG_PATH'] = OpenSSLHelper.pkg_config_dirs
    env['FIPS_MODE'] = '1'
  end

  bundle 'config force_ruby_platform true', env: env if OhaiHelper.ruby_native_gems_unsupported?
  bundle "config set --local frozen 'true'"
  bundle "config build.nokogiri --use-system-libraries --with-xml2-include=#{install_dir}/embedded/include/libxml2 --with-xslt-include=#{install_dir}/embedded/include/libxslt", env: env
  bundle "install --without #{bundle_without.join(' ')}", env: env, cwd: ruby_build_dir
  touch '.ruby-bundle' # Prevent 'make install' below from running 'bundle install' again
  bundle "exec license_finder report --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=json --columns name version licenses texts notice --save=gitaly-ruby-licenses.json", cwd: ruby_build_dir, env: env

  block 'delete grpc shared objects' do
    # Delete unused shared objects included in grpc gem
    grpc_path = shellout!("#{embedded_bin('bundle')} show grpc", env: env, cwd: ruby_build_dir).stdout.strip
    ruby_ver = shellout!("#{embedded_bin('ruby')} -e 'puts RUBY_VERSION.match(/\\d+\\.\\d+/)[0]'", env: env).stdout.chomp
    command "find #{File.join(grpc_path, 'src/ruby/lib/grpc')} ! -path '*/#{ruby_ver}/*' -name 'grpc_c.so' -type f -print -delete"
  end

  ruby_install_dir = "#{install_dir}/embedded/service/gitaly-ruby"
  command "mkdir -p #{ruby_install_dir}"
  sync './ruby/', "#{ruby_install_dir}/", exclude: ['.git', '.gitignore', 'spec', 'features']
  %w(
    LICENSE
    NOTICE
    VERSION
  ).each { |f| copy(f, ruby_install_dir) }

  make "install PREFIX=#{install_dir}/embedded", env: env

  block 'disable RubyGems in gitlab-shell hooks' do
    hooks_source_dir = File.join(ruby_build_dir, "gitlab-shell", "hooks")
    hooks_dest_dir = File.join(ruby_install_dir, "gitlab-shell", "hooks")
    env_shebang = '#!/usr/bin/env ruby'
    `grep -r -l '^#{env_shebang}' #{hooks_source_dir}`.split("\n").each do |ruby_script|
      script = File.read(ruby_script)
      erb dest: ruby_script.sub(hooks_source_dir, hooks_dest_dir),
          source: 'gitlab_shell_hooks_wrapper.erb',
          mode: 0755,
          vars: { script: script, install_dir: install_dir }
    end
  end

  command "license_finder report --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=json --columns name version licenses texts notice --save=gitaly-go-licenses.json"

  # Merge license files of ruby and go dependencies.
  block "Merge license files of ruby and go depenrencies of Gitaly" do
    require 'json'
    ruby_licenses = JSON.parse(File.read("#{ruby_build_dir}/gitaly-ruby-licenses.json"))['dependencies']
    go_licenses = JSON.parse(File.read("#{Omnibus::Config.source_dir}/gitaly/gitaly-go-licenses.json"))['dependencies']
    output = { dependencies: ruby_licenses.concat(go_licenses).uniq }
    File.write("#{install_dir}/licenses/gitaly.json", JSON.pretty_generate(output))
  end
end
