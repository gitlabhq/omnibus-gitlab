#
# Copyright:: Copyright (c) 2024 GitLab Inc.
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

name 'ruby-ffi'
description 'Rebuilds ffi gem from source to ensure correct LD_LIBRARY_PATH for Omnibus builds'
# This is a placeholder version since this software definition rebuilds an already-installed gem
# rather than building from a source. The actual version is determined by the installed ffi gem.
default_version '0.0.1'

license :project_license

skip_transitive_dependency_licensing true

dependency 'ruby'

build do
  block 'rebuild ffi gem from source' do
    env = with_standard_compiler_flags(with_embedded_path)
    gem_bin = embedded_bin('gem')
    command = %(#{embedded_bin('ruby')} -e "puts Gem::Specification.select { |x| x.name == 'ffi' }.map(&:version).uniq.map(&:to_s)")
    ffi_versions = shellout!(command, env: env).stdout || ""
    ffi_versions = ffi_versions.split("\n").map(&:strip)

    if ffi_versions.empty?
      warn 'No ffi gem installed, skipping rebuild'
      next
    end

    warn "Multiple versions of ffi found: #{ffi_versions.join(', ')}" if ffi_versions.length > 1

    shellout!("#{gem_bin} uninstall --force --all ffi", env: env)

    ffi_versions.each do |version|
      shellout!("#{gem_bin} install --no-document --platform ruby ffi -v '#{version}'",
                env: env, live_stream: log.live_stream(:info))
    end
  end
end
