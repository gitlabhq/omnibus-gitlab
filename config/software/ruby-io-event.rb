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

require "#{Omnibus::Config.project_root}/lib/gitlab/ohai_helper"
require 'shellwords'

name 'ruby-io-event'
description 'Rebuilds Ruby io-event gem with epoll_pwait2 support removed for EL 9'
# This is a placeholder version since this software definition rebuilds an already-installed gem
# rather than building from a source. The actual version is determined by the installed io-event gem.
default_version '0.0.1'

license :project_license

skip_transitive_dependency_licensing true

dependency 'ruby'

build do
  block 'rebuild io-event gem without epoll_pwait2 for EL 9' do
    # Only apply this patch for EL 9 (RHEL, Alma, Rocky, etc.)
    next unless OhaiHelper.el_9?

    env = with_standard_compiler_flags(with_embedded_path)
    gem_bin = embedded_bin('gem')
    command = %(#{embedded_bin('ruby')} -e "puts Gem::Specification.select { |x| x.name == 'io-event' }.map(&:version).uniq.map(&:to_s)")
    io_event_versions = shellout!(command).stdout || ""
    io_event_versions = io_event_versions.split("\n").map(&:strip)

    if io_event_versions.empty?
      warn 'No io-event gem installed, skipping patch'
      next
    end

    warn "Multiple versions of io-event found: #{io_event_versions.join(', ')}" if io_event_versions.length > 1

    _locations, patch_path = find_file('config/patches', 'remove-epoll-pwait2.patch')

    shellout!("#{gem_bin} install --no-document gem-patch -v 0.1.6")
    shellout!("#{gem_bin} uninstall --force --all io-event")

    io_event_versions.each do |version|
      gemfile = "io-event-#{version}.gem"
      shellout!("rm -f #{Shellwords.escape(gemfile)}")
      shellout!("#{gem_bin} fetch io-event -v #{Shellwords.escape(version)}")
      shellout!("#{gem_bin} patch -p1 #{Shellwords.escape(gemfile)} #{Shellwords.escape(patch_path)}")
      shellout!("#{gem_bin} install --no-document #{Shellwords.escape(gemfile)}",
                { env: env, live_stream: log.live_stream(:info) })
    end

    shellout!("#{gem_bin} uninstall gem-patch")
  end
end
