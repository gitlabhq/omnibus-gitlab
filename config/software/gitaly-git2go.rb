#
## Copyright:: Copyright (c) 2021 GitLab Inc
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
version = Gitlab::Version.new('gitaly')

name 'gitaly-git2go'

# Provide the previous released version of the gitaly-git2go binary for zero-downtime upgrades
default_version 'v13.12.3'

license 'MIT'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'rubygems'
dependency 'libicu'

source git: version.remote

build do
  env = with_standard_compiler_flags(with_embedded_path)

  touch '.ruby-bundle' # Prevent 'make install' from running bundle install

  block 'delete other binaries from source' do
    # Delete commands that we don't need to compile for git2go
    command "find #{File.join(build_dir, 'cmd')} ! -name 'gitaly-git2go' -type d -exec rm -rf {} +"
  end

  make "install PREFIX=#{install_dir}/embedded", env: env
end
