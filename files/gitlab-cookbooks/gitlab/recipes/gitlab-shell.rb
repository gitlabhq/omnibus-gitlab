git_user = node['gitlab']['user']['username']
git_group = node['gitlab']['user']['group']
gitlab_shell_dir = "/opt/gitlab/embedded/service/gitlab-shell"
repositories_path = node['gitlab']['gitlab-core']['repositories_path']
ssh_dir = File.join(node['gitlab']['user']['home'], ".ssh")
log_directory = node['gitlab']['gitlab-shell']['log_directory']

# Create directories because the git_user does not own its home directory
directory repositories_path do
  owner git_user
  group git_group
  recursive true
end

directory ssh_dir do
  owner git_user
  group git_group
  mode "0700"
  recursive true
end

directory log_directory do
  owner git_user
  recursive true
end

template File.join(gitlab_shell_dir, "config.yml") do
  source "gitlab-shell-config.yml.erb"
  owner git_user
  group git_group
  variables(
    :user => git_user,
    :api_url => node['gitlab']['gitlab-core']['internal_api_url'],
    :repositories_path => repositories_path,
    :authorized_keys => File.join(ssh_dir, "authorized_keys"),
    :redis_port => node['gitlab']['redis']['port'],
    :log_file => File.join(log_directory, "gitlab-shell.log")
  )
  notifies :run, "execute[bin/install]"
end

execute "bin/install" do
  cwd gitlab_shell_dir
  user git_user
  group git_group
  action :nothing
end
