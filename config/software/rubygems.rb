#
# Copyright 2016-2023 GitLab Inc.
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

name 'rubygems'
default_version '3.6.9'

license 'MIT'
license_file 'LICENSE.txt'

skip_transitive_dependency_licensing true

dependency 'ruby'

build do
  patch source: "license/add-license-file.patch"
  env = with_standard_compiler_flags(with_embedded_path)

  gem "update --no-document --system #{version}", env: env
end
