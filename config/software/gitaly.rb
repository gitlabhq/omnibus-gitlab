#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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
version = Gitlab::Version.new('gitaly')

name 'gitaly'
default_version '0ffed4e45f9ced7aec0d15187432d85d68295f7d'

license 'MIT'
license_file 'LICENSE'

dependency 'ruby'
dependency 'bundler'
dependency 'libicu'

source git: version.remote

build do
  env = with_standard_compiler_flags(with_embedded_path)

  ruby_build_dir = "#{Omnibus::Config.source_dir}/gitaly/ruby"
  # Temporary check until gitaly-ruby is in a proper release
  if File.exist?(ruby_build_dir)
    bundle 'config build.rugged --no-use-system-libraries', env: env, cwd: ruby_build_dir
    bundle 'install', env: env, cwd: ruby_build_dir
    touch '.ruby-bundle' # Prevent 'make install' below from running 'bundle install' again

    ruby_install_dir = "#{install_dir}/embedded/service/gitaly-ruby"
    command "mkdir -p #{ruby_install_dir}"
    sync './ruby/', "#{ruby_install_dir}/", exclude: ['.git', '.gitignore', 'spec', 'features']
    %w(
      LICENSE
      NOTICE
      VERSION
    ).each { |f| copy(f, ruby_install_dir) }
  end

  make "install PREFIX=#{install_dir}/embedded", env: env
end
