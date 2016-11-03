#
# Copyright:: Copyright (c) 2016 GitLab Inc
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

require 'mixlib/shellout'

CURRENT_VERSION = '9.2.18'
NEW_VERSION = '9.6.0'
DATA_DIR = '/var/opt/gitlab/postgresql/data'
INST_DIR = "#{base_path}/embedded/postgresql"

add_command_under_category 'revert-db', 'database',
                           'Run this to revert to the previous version of the database',
                           1 do |_cmd_name|
  if db_version == CURRENT_VERSION
    log "Already running #{CURRENT_VERSION}"
    exit! 1
  end

  unless Dir.exist?("#{DATA_DIR}.#{CURRENT_VERSION}")
    log "#{DATA_DIR}.#{CURRENT_VERSION} does not exist, cannot revert"
    exit! 1
  end

  log "Reverting database to #{CURRENT_VERSION} in 5 seconds"
  log "Please hit Ctrl-C now if this isn't what you were looking for"
  begin
    sleep 5
  rescue Interrupt
    log 'Received interrupt, not doing anything'
    exit! 0
  end
  revert
end

add_command_under_category 'upgrade-db', 'database',
                           'Upgrade the PostGres DB to the latest supported version',
                           1 do |_cmd_name|
  current_version = db_version

  log 'Is an omnibus managed postgresql running and upgradable?'
  if current_version.nil?
    log 'No currently installed postgresql in the omnibus instance found.' \
        'Nothing to do'
    exit! 1
  end

  unless current_version == CURRENT_VERSION
    log "psql reports #{current_version}, we're expecting " \
        "#{CURRENT_VERSION}, not sure how to proceed"
    exit! 1
  end

  unless Dir.exist?("#{INST_DIR}/#{NEW_VERSION}")
    log "#{NEW_VERSION} is not installed, cannot upgrade"
    exit! 1
  end

  unless get_all_services.member?('postgresql')
    log "No postgresql instance found, assuming you're running your own and " \
      "doing nothing"
    exit! 0
  end

  log 'Do we need to ugprade?'
  if current_version == NEW_VERSION
    log "Already at #{NEW_VERSION}, nothing to do"
    exit! 0
  end

  # In case someone altereed the db outside of the recommended parameters,
  # make sure everything is as we expect
  if File.symlink?(DATA_DIR)
    die "#{DATA_DIR} is a symlink to another directory. Will not proceed"
  end
  Dir.glob("#{INST_DIR}/#{CURRENT_VERSION}/bin/*").each do |bin_file|
    link = "#{base_path}/embedded/bin/#{File.basename(bin_file)}"
    unless File.symlink?(link) && File.readlink(link).eql?(bin_file)
      die "#{link} is not linked to #{bin_file}, unable to proceed with non-standard installation"
    end
  end
  # Get the existing locale before we move on
  (locale, encoding) = fetch_lc_collate.strip.split('.')
  log 'Stopping the database'
  run_sv_command_for_service('stop', 'postgresql')
  log 'Update the symlinks'
  create_links(NEW_VERSION)
  log 'Move the old data directory and create a new directory'
  unless run_command("mv #{DATA_DIR} #{DATA_DIR}.#{current_version}")
    die 'Error creating old directory'
  end

  unless run_command("install -d -o gitlab-psql #{DATA_DIR}")
    die 'Error creating new directory'
  end

  log 'Initialize the new database'
  run_pg_command(
    "#{base_path}/embedded/bin/initdb -D #{DATA_DIR} --locale #{locale} " \
    "--encoding #{encoding} --lc-collate=#{locale}.#{encoding} " \
    "--lc-ctype=#{locale}.#{encoding}"
  )
  results = run_pg_command(
    "#{base_path}/embedded/bin/pg_upgrade -b #{base_path}/embedded/postgresql/#{CURRENT_VERSION}/bin " \
      "-d #{DATA_DIR}.#{current_version} -D #{DATA_DIR} -B #{base_path}/embedded/bin"
  )
  log "Upgrade is complete, check output if anything else is needed: #{results}"
  log 'Run the sql scripts if needed'
  log 'Starting the db'
  run_sv_command_for_service('start', 'postgresql')
  if run_chef("#{base_path}/embedded/cookbooks/dna.json").success?
    log 'Upgrade is complete. Please verify everything is working and run the following if so'
    log "rm -rf #{DATA_DIR}/#{CURRENT_VERSION}"
    exit! 0
  else
    die 'Something went wrong during final reconfiguration, please check the logs'
  end
end

class ExecutionError < StandardError
  attr_accessor :command, :stdout, :stderr
  def initialize(command, stdout, stderr)
    @command = command
    @stdout = stdout
    @stderr = stderr
  end
end

def get_command_output(command)
  shell_out = Mixlib::ShellOut.new(command)
  shell_out.run_command
  begin
    shell_out.error!
  rescue Mixlib::ShellOut::ShellCommandFailed
    raise ExecutionError.new(command, shell_out.stdout, shell_out.stderr)
  end
  shell_out.stdout
end

def run_pg_command(command)
  begin
    results = get_command_output("su - gitlab-psql -c \"#{command}\"")
  rescue ExecutionError => e
    log "Could not run: #{command}"
    log "STDOUT: #{e.stdout}"
    log "STDERR: #{e.stderr}"
    die 'Please check the logs and try again'
  end
  results
end

def db_version
  get_command_output("#{base_path}/embedded/bin/pg_ctl --version").split.last
end

def fetch_lc_collate
  run_pg_command(
    "#{base_path}/embedded/bin/psql -h #{DATA_DIR}/.. -d postgres -c 'SHOW LC_COLLATE' -q -t"
  )
end

def create_links(version)
  Dir.glob("#{INST_DIR}/#{version}/bin/*").each do |bin_file|
    destination = "#{base_path}/embedded/bin/#{File.basename(bin_file)}"
    get_command_output("ln -sf #{bin_file} #{destination}")
  end
end

def revert
  log '== Reverting =='
  run_sv_command_for_service('stop', 'postgresql')
  if Dir.exist?("#{DATA_DIR}.#{CURRENT_VERSION}")
    run_command("rm -rf #{DATA_DIR}")
    run_command("mv #{DATA_DIR}.#{CURRENT_VERSION} #{DATA_DIR}")
  end
  create_links(CURRENT_VERSION)
  run_sv_command_for_service('start', 'postgresql')
  log '== Reverted =='
end

def die(message)
  log '== Fatal error =='
  log message
  revert
  log "== Reverted to #{CURRENT_VERSION}. Please check log output for what went wrong =="
  exit 1
end
