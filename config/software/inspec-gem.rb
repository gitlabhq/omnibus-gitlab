#
# Copyright 2012-2014 Chef Software, Inc.
# Copyright 2017-2022 GitLab Inc.
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
require 'mixlib/shellout'

name 'inspec-gem'
# The version here should be in agreement with the chef-bin/cinc version and
# /Gemfile.lock so that our rspec testing stays consistent with the package
# contents.
default_version '6.6.0'

license 'MIT'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'omnibus-gitlab-gems'

build do
  env = with_standard_compiler_flags(with_embedded_path)

  block 'patch inspec files' do
    prefix_path = "#{install_dir}/embedded"
    gem_path = shellout!("#{embedded_bin('ruby')} -e \"puts Gem.path.find { |path| path.start_with?(\'#{prefix_path}\') }\"", env: env).stdout.chomp

    # This can be dropped when inspec is updated with https://github.com/inspec/inspec/issues/7030
    patch source: "fix-uninitialized-constant-parser-mixin.patch",
          target: "#{gem_path}/gems/inspec-core-#{version}/lib/inspec/utils/profile_ast_helpers.rb"
  end
end
