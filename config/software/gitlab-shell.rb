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
version = Gitlab::Version.new('gitlab-shell')

name 'gitlab-shell'
default_version version.print

license 'MIT'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'ruby'

source git: version.remote

build do
  env = with_standard_compiler_flags(with_embedded_path)
  command "mkdir -p #{install_dir}/embedded/service/gitlab-shell"
  command 'make build', env: env
  sync './', "#{install_dir}/embedded/service/gitlab-shell/", exclude: ['.git', '.gitignore', 'go', 'go_build']
end
