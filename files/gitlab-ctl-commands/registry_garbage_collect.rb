#
# Copyright:: Copyright (c) 2016 GitLab Inc.
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

require 'shellwords'

add_command_under_category 'registry-garbage-collect', 'container-registry', 'Run Container Registry garbage collection.', 2 do |cmd_name, path|
  result = RegistryGarbageCollect.new(self, path, ARGV).execute!
  Kernel.exit !!result
end

class RegistryGarbageCollect
  def initialize(ctl, path, args)
    @ctl = ctl
    @path = path || '/var/opt/gitlab/registry/config.yml'
    @args = args

    @command = %w(/opt/gitlab/embedded/bin/registry garbage-collect)
    @command << @path

    parse_options!
  end

  def execute!
    unless enabled?
      log "Container registry is not enabled, exiting..."
      return
    end

    unless config?
      log "Didn't find #{@path}, please supply the path to registry config.yml file, eg: gitlab-ctl registry-garbage-collect /path/to/config.yml"
      return
    end

    stop!

    begin
      log "Running garbage-collect using configuration #{@command}, this might take a while...\n"
      status = @ctl.run_command(@command.shelljoin)

      unless status.exitstatus.zero?
        log "\nFailed to run garbage-collect command, starting registry service."
        return
      end

      true
    ensure
      start!
    end
  end

  private

  def log(*args)
    @ctl.log(*args)
  end

  def start!
    @ctl.run_sv_command_for_service('start', service_name)
  end

  def stop!
    @ctl.run_sv_command_for_service('stop', service_name)
  end

  def enabled?
    @ctl.service_enabled?(service_name)
  end

  def config?
    File.exist?(@path)
  end

  def service_name
    "registry"
  end

  def parse_options!
    OptionParser.new do |opts|
      opts.on('-m', '--delete-manifests', '--delete-untagged', 'Delete manifests that are not currently referenced via tag') do
        @command << "-m"
      end
    end.parse!(@args)
  end
end
