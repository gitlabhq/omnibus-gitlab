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
require 'optparse'

options = {}

OptionParser.new do |opts|
  opts.on('-tDIR', '--tmp-dir=DIR', 'Storage location for temporary data') do |t|
    options[:tmp_dir] = t
  end
end.parse!(ARGV)

DATA_DIR = "#{data_path}/postgresql/data".freeze
INST_DIR = "#{base_path}/embedded/postgresql".freeze
TMP_DATA_DIR = options.key?(:tmp_dir) ? "#{options[:tmp_dir]}/data" : DATA_DIR

add_command_under_category 'revert-pg-upgrade', 'database',
                           'Run this to revert to the previous version of the database',
                           1 do |_cmd_name|
  running_version = fetch_running_version
  if running_version == default_version
    log "Already running #{default_version}"
    exit! 1
  end

  unless Dir.exist?("#{TMP_DATA_DIR}.#{default_version}")
    log "#{TMP_DATA_DIR}.#{default_version} does not exist, cannot revert data"
    log 'Will proceed with reverting the running program version only,  unless you interrupt'
  end

  log "Reverting database to #{default_version} in 5 seconds"
  log "Please hit Ctrl-C now if this isn't what you were looking for"
  begin
    sleep 5
  rescue Interrupt
    log 'Received interrupt, not doing anything'
    exit! 0
  end
  revert
end

add_command_under_category 'pg-upgrade', 'database',
                           'Upgrade the PostgreSQL DB to the latest supported version',
                           1 do |_cmd_name|
  running_version = fetch_running_version

  log 'Is an omnibus managed postgresql running and upgradable?'
  if running_version.nil?
    log 'No currently installed postgresql in the omnibus instance found.' \
        'Nothing to do'
    exit! 1
  end

  unless running_version == default_version
    log "psql reports #{running_version}, we're expecting " \
        "#{default_version}, not sure how to proceed"
    exit! 1
  end

  if upgrade_version.nil?
    log "No new version of PostgreSQL installed, nothing to upgrade to"
    exit! 1
  end

  unless Dir.exist?("#{INST_DIR}/#{upgrade_version}")
    log "#{upgrade_version} is not installed, cannot upgrade"
    exit! 1
  end

  unless get_all_services.member?('postgresql')
    log "No postgresql instance found, assuming you're running your own and " \
      'doing nothing'
    exit! 0
  end

  log 'Do we need to ugprade?'
  if running_version == upgrade_version
    log "Already at #{upgrade_version}, nothing to do"
    exit! 0
  end

  # In case someone altered the db outside of the recommended parameters,
  # make sure everything is as we expect
  if File.symlink?(DATA_DIR)
    die "#{DATA_DIR} is a symlink to another directory. Will not proceed"
  end

  Dir.glob("#{INST_DIR}/#{default_version}/bin/*").each do |bin_file|
    link = "#{base_path}/embedded/bin/#{File.basename(bin_file)}"
    unless File.symlink?(link) && File.readlink(link).eql?(bin_file)
      die "#{link} is not linked to #{bin_file}, unable to proceed with non-standard installation"
    end
  end

  # Get the existing locale before we move on
  locale, encoding = fetch_lc_collate.strip.split('.')
  log 'Stopping the database'
  run_sv_command_for_service('stop', 'postgresql')
  log 'Update the symlinks'
  create_links(upgrade_version)

  unless run_command("install -d -o gitlab-psql #{TMP_DATA_DIR}.#{upgrade_version}")
    die 'Error creating new directory'
  end

  log 'Initialize the new database'
  run_pg_command(
    "#{base_path}/embedded/bin/initdb -D #{TMP_DATA_DIR}.#{upgrade_version} --locale #{locale} " \
    "--encoding #{encoding} --lc-collate=#{locale}.#{encoding} " \
    "--lc-ctype=#{locale}.#{encoding}"
  )
  results = run_pg_command(
    "#{base_path}/embedded/bin/pg_upgrade -b #{base_path}/embedded/postgresql/#{default_version}/bin " \
    "-d #{DATA_DIR} -D #{TMP_DATA_DIR}.#{upgrade_version} -B #{base_path}/embedded/bin"
  )

  log 'Move the old data directory out of the way'
  unless run_command("mv #{DATA_DIR} #{TMP_DATA_DIR}.#{default_version}")
    die 'Error moving data for older version, '
  end

  log 'Rename the new data directory'
  unless run_command("mv #{TMP_DATA_DIR}.#{upgrade_version} #{DATA_DIR}")
    die "Error moving #{TMP_DATA_DIR}.#{upgrade_version} to #{DATA_DIR}"
  end

  log "Upgrade is complete: #{results}"
  log 'Running reconfigure'
  if run_chef("#{base_path}/embedded/cookbooks/dna.json").success?
    log 'Database upgrade is complete, running analyze_new_cluster.sh'
    run_pg_command("#{DATA_DIR}/../analyze_new_cluster.sh")
    log '==== Upgrade has completed ===='
    log 'Please verify everything is working and run the following if so'
    log "rm -rf #{TMP_DATA_DIR}.#{default_version}"
    exit! 0
  else
    die 'Something went wrong during final reconfiguration, please check the output'
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
    die 'Please check the output and try again'
  end
  results
end

def fetch_running_version
  get_command_output("#{base_path}/embedded/bin/pg_ctl --version").split.last
end

def version_from_manifest(software)
  if @versions.nil?
    @versions = JSON.parse(File.read("#{base_path}/version-manifest.json"))
  end
  if @versions['software'].key?(software)
    return @versions['software'][software]['described_version']
  end
  nil
end

def default_version
  version_from_manifest('postgresql')
end

def upgrade_version
  version_from_manifest('postgresql_new')
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
  if Dir.exist?("#{TMP_DATA_DIR}.#{default_version}")
    run_command("rm -rf #{DATA_DIR}")
    run_command("mv #{TMP_DATA_DIR}.#{default_version} #{DATA_DIR}")
  end
  create_links(default_version)
  run_sv_command_for_service('start', 'postgresql')
  log'== Reverted =='
end

def die(message)
  log '== Fatal error =='
  log message
  revert
  log "== Reverted to #{default_version}. Please check output for what went wrong =="
  exit 1
end
