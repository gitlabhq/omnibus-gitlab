#
# Copyright:: Copyright (c) 2014 GitLab B.V.
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

define :unicorn_service, :rails_app => nil, :user => nil do
  rails_app = params[:rails_app]
  rails_home = node['gitlab'][rails_app]['dir']
  svc = params[:name]
  user = params[:user]

  unicorn_etc_dir = File.join(rails_home, "etc")
  unicorn_working_dir = File.join(rails_home, "working")

  unicorn_listen_socket = node['gitlab'][svc]['socket']
  unicorn_pidfile = node['gitlab'][svc]['pidfile']
  unicorn_log_dir = node['gitlab'][svc]['log_directory']
  unicorn_socket_dir = File.dirname(unicorn_listen_socket)

  [
    unicorn_log_dir,
    File.dirname(unicorn_pidfile)
  ].each do |dir_name|
    directory dir_name do
      owner user
      mode '0700'
      recursive true
    end
  end

  directory unicorn_socket_dir do
    owner user
    group node['gitlab']['web-server']['group']
    mode '0750'
    recursive true
  end

  unicorn_listen_tcp = [node['gitlab'][svc]['listen'], node['gitlab'][svc]['port']].join(':')

  unicorn_rb = File.join(unicorn_etc_dir, "unicorn.rb")
  unicorn_config unicorn_rb do
    listen(
      unicorn_listen_tcp => {
        :tcp_nopush => node['gitlab'][svc]['tcp_nopush']
      },
      unicorn_listen_socket => {
        :backlog => node['gitlab'][svc]['backlog_socket'],
      }
    )
    worker_timeout node['gitlab'][svc]['worker_timeout']
    working_directory unicorn_working_dir
    worker_processes node['gitlab'][svc]['worker_processes']
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
    notifies :restart, "service[#{svc}]" if OmnibusHelper.should_notify?(svc)
  end

  runit_service svc do
    down node['gitlab'][svc]['ha']
    restart_command 2 # Restart Unicorn using SIGUSR2
    template_name 'unicorn'
    options({
      :service => svc,
      :user => user,
      :rails_app => rails_app,
      :unicorn_rb => unicorn_rb,
      :log_directory => unicorn_log_dir
    }.merge(params))
    log_options node['gitlab']['logging'].to_hash.merge(node['gitlab'][svc].to_hash)
  end

  if node['gitlab']['bootstrap']['enable']
    execute "/opt/gitlab/bin/gitlab-ctl start #{svc}" do
      retries 20
    end
  end
end
