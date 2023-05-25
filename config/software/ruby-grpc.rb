#
# Copyright:: Copyright (c) 2017-2022 GitLab Inc.
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

name 'ruby-grpc'
description 'Reinstalls Ruby grpc gem with system OpenSSL'
default_version '0.0.1'

license :project_license

skip_transitive_dependency_licensing true

dependency 'ruby'

build do
  block 're-install grpc gem with system OpenSSL' do
    env = with_standard_compiler_flags(with_embedded_path)
    gem_bin = embedded_bin('gem')
    command = %(#{embedded_bin('ruby')} -e "puts Gem::Specification.select { |x| x.name == 'grpc' }.map(&:version).uniq.map(&:to_s)")
    grpc_versions = shellout!(command).stdout || ""
    grpc_versions = grpc_versions.split("\n").map(&:strip)

    raise 'No gRPC versions installed, failing build' if grpc_versions.empty?

    warn "Multiple versions of gRPC found: #{grpc_versions.join(', ')}" if grpc_versions.length > 1

    patches = {}

    grpc_versions.each do |version|
      source =
        # https://github.com/grpc/grpc/pull/27660 significantly changed the extconf.rb for TruffleRuby
        if Gem::Version.new(version) < Gem::Version.new('1.48.0')
          'grpc-system-ssl-1.42.0.patch'
        else
          'grpc-system-ssl-1.48.0.patch'
        end

      _locations, patch_path = find_file('config/patches', source)
      patches[version] = patch_path
    end

    shellout!("#{gem_bin} install --no-document gem-patch -v 0.1.6")
    shellout!("#{gem_bin} uninstall --force --all grpc")

    # This works around an issue with the grpc gem attempting to include
    # /opt/gitlab/include headers instead of the vendored re2 headers:
    # https://github.com/grpc/grpc/pull/32580. This can be removed
    # after grpc is updated with that pull request.
    env['CPPFLAGS'] = "-Ithird_party/re2 #{env['CPPFLAGS']}"

    grpc_versions.each do |version|
      patch_path = patches[version]
      gemfile = "grpc-#{version}.gem"
      shellout!("rm -f #{gemfile}")
      shellout!("#{gem_bin} fetch grpc -v #{version} --platform ruby")
      shellout!("#{gem_bin} patch -p1 #{gemfile} #{patch_path}")
      shellout!("#{gem_bin} install --platform ruby --no-document #{gemfile}", env: env)
    end

    shellout!("#{gem_bin} uninstall gem-patch")
  end
end
