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

name 'omnibus-gitlab-gems'

default_version '20240605-16-3'

license 'MIT'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'ruby'
# If libarchive is present in system library locations and not bundled with
# omnibus-gitlab package, then Chef will incorrectly attempt to use it, and can
# potentially fail as seen from
# https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7741. Hence, we need to
# bundle libarchive in the package.
dependency 'libarchive'
dependency 'rubygems'

build do
  gemfile_dir = "#{install_dir}/embedded/service/omnibus-gitlab"

  mkdir gemfile_dir
  gemfile = File.join(Omnibus::Config.project_root, 'config/templates/omnibus-gitlab-gems/Gemfile')
  gemfile_lock = "#{gemfile}.lock"

  [gemfile, gemfile_lock].each do |filename|
    copy filename, gemfile_dir
  end

  env = with_standard_compiler_flags(with_embedded_path)

  target_gemfile = File.join(gemfile_dir, 'Gemfile')
  env['BUNDLE_GEMFILE'] = target_gemfile
  bundle "config set --local frozen 'true'", env: env
  bundle "install --jobs #{workers} --retry 5", env: env
  bundle "exec license_finder report --project_path=#{gemfile_dir} --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=json --columns name version licenses texts notice --save=license.json", env: env
  copy "license.json", "#{install_dir}/licenses/omnibus-gitlab-gems.json"
end
