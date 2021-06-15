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

# Skip the gitaly dependency if already loaded by the project. This improves build-ordering,
# due to how omnibus orders the components. Components that are dependencies of other components
# get moved in front of ones that are only defined in the project. Without this gate, gitaly
# ends up in front of components that change less frequently.
# Omnibus Build order: https://github.com/chef/omnibus/blob/c872e61c30d2b3f88ead03bd1254ff96d37059a3/lib/omnibus/library.rb#L64
dependency 'gitaly' unless project.dependencies.include?('gitaly')
dependency 'libicu'
dependency 'pkg-config-lite'

source git: version.remote

build do
  env = with_standard_compiler_flags(with_embedded_path)

  touch '.ruby-bundle' # Prevent 'make install' from running bundle install

  # Delete commands that we don't need to compile for git2go
  command "find #{File.join(project_dir, 'cmd')} -mindepth 1 -maxdepth 1 ! -name 'gitaly-git2go' -type d -exec rm -rf {} +"

  make "install PREFIX=#{install_dir}/embedded", env: env
end
