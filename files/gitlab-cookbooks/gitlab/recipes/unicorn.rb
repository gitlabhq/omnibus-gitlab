#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2014 GitLab.com
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

gitlab_rails_dir = node['gitlab']['gitlab-rails']['dir']
gitlab_rails_etc_dir = File.join(gitlab_rails_dir, "etc")
gitlab_rails_working_dir = File.join(gitlab_rails_dir, "working")

unicorn_listen_socket = node['gitlab']['unicorn']['socket']
unicorn_pidfile = node['gitlab']['unicorn']['pidfile']
unicorn_log_dir = node['gitlab']['unicorn']['log_directory']
unicorn_socket_dir = File.dirname(unicorn_listen_socket)

[
  unicorn_log_dir,
  File.dirname(unicorn_pidfile)
].each do |dir_name|
  directory dir_name do
    owner node['gitlab']['user']['username']
    mode '0700'
    recursive true
  end
end

directory unicorn_socket_dir do
  owner node['gitlab']['user']['username']
  group node['gitlab']['webserver']['username']
  mode '0750'
  recursive true
end

unicorn_listen_tcp = node['gitlab']['unicorn']['listen']
unicorn_listen_tcp << ":#{node['gitlab']['unicorn']['port']}"

unicorn_config File.join(gitlab_rails_etc_dir, "unicorn.rb") do
  listen(
    unicorn_listen_tcp => {
      :tcp_nopush => node['gitlab']['unicorn']['tcp_nopush']
    },
    unicorn_listen_socket => {
      :backlog => node['gitlab']['unicorn']['backlog_socket'],
    }
  )
  worker_timeout node['gitlab']['unicorn']['worker_timeout']
  working_directory gitlab_rails_working_dir
  worker_processes node['gitlab']['unicorn']['worker_processes']
  preload_app true
  stderr_path File.join(unicorn_log_dir, "unicorn_stderr.log")
  stdout_path File.join(unicorn_log_dir, "unicorn_stdout.log")
  pid unicorn_pidfile
  before_fork <<-'EOS'
    old_pid = "#{server.config[:pid]}.oldbin"
    if old_pid != server.pid
      begin
        sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
        Process.kill(sig, File.read(old_pid).to_i)
      rescue Errno::ENOENT, Errno::ESRCH
      end
    end
  EOS
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, 'service[unicorn]' if OmnibusHelper.should_notify?("unicorn")
end

runit_service "unicorn" do
  down node['gitlab']['unicorn']['ha']
  restart_command 2 # Restart Unicorn using SIGUSR2
  options({
    :log_directory => unicorn_log_dir
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['unicorn'].to_hash)
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start unicorn" do
    retries 20
  end
end
