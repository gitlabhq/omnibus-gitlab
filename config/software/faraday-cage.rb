#
## Copyright:: Copyright (c) 2021 GitLab Inc.
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
#

name 'faraday-cage'

# On this date, we discovered that many, many, many Gemfile and Gemspecs
# install the latest version of Faraday. This, in turn, installs a version
# of the net-http gem which causes conflicts that prevent package
# installation and gitlab-ctl reconfigure.
default_version '20240109'

license 'MIT'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'ruby'

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # pin the version of faraday and faraday-net_http temporarily until
  # conflicts between the version of net-http it requires and the version of
  # net-http shipped in the Gemfile can be resolved
  gem 'install faraday-net_http' \
      " --clear-sources" \
      " -s https://packagecloud.io/cinc-project/stable" \
      " -s https://rubygems.org" \
      " --version '3.0.2'" \
      " --bindir '#{install_dir}/embedded/bin'" \
      ' --no-document', env: env

  gem 'install faraday' \
      " --clear-sources" \
      " -s https://packagecloud.io/cinc-project/stable" \
      " -s https://rubygems.org" \
      " --version '2.8.1'" \
      " --bindir '#{install_dir}/embedded/bin'" \
      ' --no-document', env: env
end
