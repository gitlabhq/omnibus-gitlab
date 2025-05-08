#
# Copyright:: Copyright (c) 2012-2014 Chef Software, Inc.
# Copyright:: Copyright (c) 2014 GitLab Inc.
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
version = Gitlab::Version.new('nginx-module-vts', '0.2.2')
default_version version.print

license 'BSD-2-Clause'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

source git: version.remote

# This is a source-only package for nginx, but we need to populate /opt/gitlab
# to ensure Omnibus build cache extracts the right tag.
build do
  dest_dir = File.join(install_dir, "src", "nginx_modules", name)

  mkdir dest_dir

  sync './', dest_dir
end
