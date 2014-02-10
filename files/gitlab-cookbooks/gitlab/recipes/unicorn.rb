gitlab_core_dir = node['gitlab']['gitlab-core']['dir']
gitlab_core_etc_dir = File.join(gitlab_core_dir, "etc")
gitlab_core_working_dir = File.join(gitlab_core_dir, "working")

unicorn_listen_socket = node['gitlab']['unicorn']['socket']
unicorn_log_dir = node['gitlab']['unicorn']['log_directory']
unicorn_socket_dir = File.dirname(unicorn_listen_socket)

[
  unicorn_log_dir,
  unicorn_socket_dir
].each do |dir_name|
  directory dir_name do
    owner node['gitlab']['user']['username']
    mode '0700'
    recursive true
  end
end

unicorn_listen_tcp = node['gitlab']['gitlab-core']['listen']
unicorn_listen_tcp << ":#{node['gitlab']['gitlab-core']['port']}"

unicorn_config File.join(gitlab_core_etc_dir, "unicorn.rb") do
  listen(
    unicorn_listen_tcp => {
      :tcp_nopush => node['gitlab']['unicorn']['tcp_nopush']
    },
    unicorn_listen_socket => {
      :backlog => node['gitlab']['unicorn']['backlog_socket'],
    }
  )
  worker_timeout node['gitlab']['unicorn']['worker_timeout']
  working_directory gitlab_core_working_dir
  worker_processes node['gitlab']['unicorn']['worker_processes']
  preload_app true
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, 'service[unicorn]' if OmnibusHelper.should_notify?("unicorn")
end

runit_service "unicorn" do
  down node['gitlab']['unicorn']['ha']
  options({
    :log_directory => unicorn_log_dir
  }.merge(params))
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start unicorn" do
    retries 20
  end
end
