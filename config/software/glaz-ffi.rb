#
# Copyright:: Copyright (c) 2026 GitLab Inc.
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
require "#{Omnibus::Config.project_root}/lib/gitlab/build/glaz_ffi"

name 'glaz-ffi'

# Pinned version and per-architecture checksums live in config/software_versions.yml.
default_version Build::GlazFFI.version.upstream_version

license 'MIT'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

source Build::GlazFFI.source_args

relative_path Build::GlazFFI.bundle_dir_name

build do
  # The licensing machinery only warns about a missing license file; fail
  # instead, so a repackaged bundle cannot ship without its license texts.
  block 'assert the bundle carries its license files' do
    %w[LICENSE licenses/crates.txt].each do |f|
      raise "glaz-ffi bundle has no #{f}" unless File.exist?(File.join(project_dir, f))
    end
  end

  # Stage the link inputs for gitlab-kas below the install dir: the build
  # cache restores the install dir but skips fetch extraction, so a
  # cache-restored glaz-ffi must still serve a gitlab-kas rebuild. The
  # package excludes this directory (config/projects/gitlab.rb).
  mkdir Build::GlazFFI.dir(install_dir)
  copy 'libglaz_ffi.a', Build::GlazFFI.dir(install_dir)
  copy 'glaz_ffi.h', Build::GlazFFI.dir(install_dir)
  copy 'native-static-libs.txt', Build::GlazFFI.dir(install_dir)
  # gitlab-kas checks the manifest's version against its own pin at link time.
  copy 'manifest.json', Build::GlazFFI.dir(install_dir)

  # license_finder cannot see inside a static archive; ship GLAZ's own crate inventory.
  mkdir "#{install_dir}/licenses"
  copy 'licenses/crates.txt', "#{install_dir}/licenses/glaz-ffi-crates.txt"
end
