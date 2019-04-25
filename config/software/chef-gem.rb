#
# Copyright 2012-2014 Chef Software, Inc.
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

name 'chef-gem'
# The version here should be in agreement with /Gemfile.lock so that our rspec
# testing stays consistent with the package contents.
default_version '13.6.4'

license 'Apache-2.0'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'ruby'
dependency 'rubygems'
dependency 'libffi'
dependency 'rb-readline'

build do
  patch source: "license/#{version}/add-license-file.patch"
  env = with_standard_compiler_flags(with_embedded_path)

  gem 'install chef' \
      " --version '#{version}'" \
      " --bindir '#{install_dir}/embedded/bin'" \
      ' --no-document', env: env

  # Ruby 2.6 deprecates Net::HTTPServerException in favor of Net::HTTPClientException.
  # To avoid warnings, we generate a patch via:
  #
  # git grep --name-only HTTPServerException | xargs -I {} sed -i -e "s/HTTPServerException/HTTPClientException/g" {}
  #
  # This can go away once Chef is upgraded to at least 14.9.13.
  command "patch -d #{install_dir}/embedded/lib/ruby/gems/2.6.0/gems/chef-#{default_version} -p1 < #{Omnibus::Config.project_root}/config/patches/chef-gem/ruby/#{version}/net-server-exception.patch"
end
