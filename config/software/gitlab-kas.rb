#
# Copyright:: Copyright (c) 2020 GitLab Inc.
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
require "#{Omnibus::Config.project_root}/lib/gitlab/build/glaz_ffi"
version = Gitlab::Version.new('gitlab-kas')

name 'gitlab-kas'
default_version version.print

license 'MIT'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

# The GLAZ policy engine, linked statically into the kas binary.
dependency 'glaz-ffi'

source git: version.remote

build do
  # The gitlab-kas source tree pins the glaz-ffi version and checksums it was
  # built and tested against (MODULE.bazel), parsed here with the script the
  # tree bundles, so parser and pin format always come from the same commit.
  # Fail when our pin drifts, so a mismatched engine can never ship silently.
  block 'verify the glaz-ffi pin against the gitlab-kas source tree' do
    pin = shellout!('awk -f build/glaz_ffi_pin.awk MODULE.bazel', cwd: project_dir).stdout
    kas_pin = {
      'version' => pin[/^version (\S+)$/, 1],
      'x86_64' => pin[/^sha256 x86_64-unknown-linux-gnu (\S+)$/, 1],
      'aarch64' => pin[/^sha256 aarch64-unknown-linux-gnu (\S+)$/, 1],
    }

    # Distinguish a parser breakage from real drift: nil captures mean the awk
    # output changed shape, not that the pins disagree.
    if kas_pin.values.any?(&:nil?)
      raise "could not parse the glaz-ffi pin from the gitlab-kas source tree; " \
            "build/glaz_ffi_pin.awk printed: #{pin.inspect}"
    end

    our_pin = Build::GlazFFI.version.then do |v|
      { 'version' => v.upstream_version }.merge(v.source_sha256.slice('x86_64', 'aarch64'))
    end

    unless kas_pin == our_pin
      raise "glaz-ffi pin drift: gitlab-kas pins #{kas_pin.inspect}, " \
            "this build pins #{our_pin.inspect}. Update the glaz-ffi entry in " \
            "config/software_versions.yml to the values gitlab-kas pins."
    end
  end

  env = {
    'TARGET_DIRECTORY' => "#{Omnibus::Config.source_dir}/gitlab-kas/build",
    'GIT_REF' => version.print,
    'GLAZ_FFI_DIR' => Build::GlazFFI.dir(install_dir),
  }
  make 'kas', env: env

  # make ignores variables it has no rule for: a gitlab-kas source without the
  # GLAZ_FFI_DIR seam builds green here and ships without the engine. Assert
  # the outcome, not the input: the linked library exports this symbol.
  block 'assert the kas binary contains the GLAZ engine' do
    binary = "#{Omnibus::Config.source_dir}/gitlab-kas/build/kas"
    # grep exits non-zero for a missing file too; do not report that as a
    # missing engine.
    raise "gitlab-kas build produced no binary at #{binary}" unless File.exist?(binary)

    unless shellout("grep -q glaz_ffi_abi_version '#{binary}'").exitstatus.zero?
      raise "gitlab-kas built without the GLAZ engine: glaz_ffi_abi_version is " \
            "not in #{binary}. The gitlab-kas source at this version likely has " \
            "no GLAZ_FFI_DIR seam in its Makefile."
    end
  end

  mkdir "#{install_dir}/embedded/bin/"
  move 'build/kas', "#{install_dir}/embedded/bin/gitlab-kas"

  command "license_finder report --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=json --columns name version licenses texts notice --save=license.json"
  copy "license.json", "#{install_dir}/licenses/gitlab-kas.json"
end
