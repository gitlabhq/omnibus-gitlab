account_helper = AccountHelper.new(node)

# We create shared_path with 751 allowing other users to enter into the directories
# It's needed, because by default the shared_path is used to store pages which are served by gitlab-www:gitlab-www
storage_directory node['gitlab']['gitlab-rails']['shared_path'] do
  owner account_helper.gitlab_user
  group account_helper.web_server_group
  mode '0751'
end

storage_directory node['gitlab']['gitlab-rails']['pages_path'] do
  owner account_helper.gitlab_user
  group account_helper.web_server_group
  mode '0750'
end
