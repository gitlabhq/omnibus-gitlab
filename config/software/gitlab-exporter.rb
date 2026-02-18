#
# Copyright 2016-2022 GitLab Inc.
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

name 'gitlab-exporter'
default_version '16.4.0'
license 'MIT'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'ruby'
dependency 'rubygems'
dependency 'postgresql'

build do
  patch source: 'add-license-file.patch'

  env = with_standard_compiler_flags(with_embedded_path)
  args = "--no-document --version #{version}"
  args += " --platform ruby" if OhaiHelper.ruby_native_gems_unsupported?
  gem "install gitlab-exporter #{args}", env: env
end
