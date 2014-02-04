git_user = node['gitlab']['user']['username']
gitlab_shell_dir = "/opt/gitlab/embedded/service/gitlab-shell"
repositories_path = node['gitlab']['gitlab-core']['repositories_path']
ssh_dir = File.join(node['gitlab']['user']['home'], ".ssh")

# Create directories because the git_user does not own its home directory
directory repositories_path do
  owner git_user
end

directory ssh_dir do
  owner git_user
  mode "0700"
end

template File.join(gitlab_shell_dir, "config.yml") do
  source "gitlab-shell-config.yml.erb"
  owner git_user
  variables(
    :user => git_user,
    :api_url => node['gitlab']['gitlab-core']['internal_api_url'],
    :repositories_path => repositories_path,
    :ssh_dir => ssh_dir,
    :redis_port => node['gitlab']['redis']['port'],
    :log_directory => node['gitlab']['gitlab-shell']['log_directory']
  )
  notifies :run, "execute[bin/install]"
end

execute "bin/install" do
  cwd gitlab_shell_dir
  user git_user
  action :nothing
end
