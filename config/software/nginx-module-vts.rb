#
# Copyright:: Copyright (c) 2012-2014 Chef Software, Inc.
# Copyright:: Copyright (c) 2014 GitLab B.V.
# License:: Apache License, Version 2.0
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

require "#{Omnibus::Config.project_root}/lib/gitlab/version"

name 'nginx-module-vts'
version = Gitlab::Version.new('nginx-module-vts', '0.1.18')
default_version version.print

license 'BSD-2-Clause'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

source git: version.remote

build do
  patch source: 'fix-compile-errors-in-gcc-11.patch'
end

# This is a source-only package for nginx.
