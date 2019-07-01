#
# Copyright 2016 GitLab Inc.
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

name 'ohai'
# The version here should be in agreement with /Gemfile.lock so that our rspec
# testing stays consistent with the package contents.
version = Gitlab::Version.new('ohai', '14-8-13-gitlab')
default_version version.print(false)

source git: version.remote

license 'Apache-2.0'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'ruby'
dependency 'rubygems'

build do
  env = with_standard_compiler_flags(with_embedded_path)

  gem 'build ohai.gemspec'
  gem 'install ohai' \
      " --bindir '#{install_dir}/embedded/bin'" \
      ' --no-document' \
      " ohai-14.8.13.gem", env: env
end
