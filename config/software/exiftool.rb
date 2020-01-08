#
# Copyright:: Copyright (c) 2019 GitLab Inc.
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

name 'exiftool'
version = Gitlab::Version.new('exiftool', '11.70')
default_version version.print(false)

license 'GPL-1.0 or Artistic'
license_file 'LICENSE.txt'

skip_transitive_dependency_licensing true

source git: version.remote

build do
  # exiftool has a hardcoded list of locations where it looks for libraries. We
  # patch it to add the bundled one
  patch source: 'lib-location.patch'

  # exiftool doesn't provide a license file, so we create one based on info
  # from the website
  patch source: 'add-license-file.patch'

  # Ensuring a bin directory exists
  command "mkdir -p #{install_dir}/embedded/bin"

  # Copying necessary files from source
  sync "lib", "#{install_dir}/embedded/lib/exiftool-perl"
  copy "exiftool", "#{install_dir}/embedded/bin/exiftool"
end
