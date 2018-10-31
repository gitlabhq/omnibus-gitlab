shared_examples 'enabled gitlab-rails env' do |env_var, content|
  it 'created env directory' do
    expect(chef_run).to create_directory("/opt/gitlab/etc/gitlab-rails/env")
  end

  it "does create the #{env_var} file" do
    expect(chef_run).to create_file("/opt/gitlab/etc/gitlab-rails/env/#{env_var}").with_content(
      /#{content}/
    )
  end
end

shared_examples 'disabled gitlab-rails env' do |env_var, content|
  it 'created env directory' do
    expect(chef_run).to create_directory("/opt/gitlab/etc/gitlab-rails/env")
  end

  it "does not create the #{env_var} file" do
    expect(chef_run).not_to create_file("/opt/gitlab/etc/gitlab-rails/env/#{env_var}").with_content(
      /#{content}/
    )
  end
end

shared_examples 'enabled gitlab-workhorse env' do |env_var, content|
  it 'created env directory' do
    expect(chef_run).to create_directory("/opt/gitlab/etc/gitlab-workhorse/env")
  end

  it "does create the #{env_var} file" do
    expect(chef_run).to create_file("/opt/gitlab/etc/gitlab-workhorse/env/#{env_var}").with_content(
      /#{content}/
    )
  end
end

shared_examples 'enabled mattermost env' do |env_var, content|
  it 'created env directory' do
    expect(chef_run).to create_directory("/var/opt/gitlab/mattermost/env")
  end

  it "does create the #{env_var} file" do
    expect(chef_run).to create_file("/var/opt/gitlab/mattermost/env/#{env_var}").with_content(
      /#{content}/
    )
  end
end

shared_examples 'disabled mattermost env' do |env_var, content|
  it 'created env directory' do
    expect(chef_run).to create_directory("/var/opt/gitlab/mattermost/env")
  end

  it "does not create the #{env_var} file" do
    expect(chef_run).not_to create_file("/var/opt/gitlab/mattermost/env/#{env_var}").with_content(
      /#{content}/
    )
  end
end

shared_examples 'enabled gitaly env' do |env_var, content|
  it 'created env directory' do
    expect(chef_run).to create_directory("/opt/gitlab/etc/gitaly")
  end

  it "does create the #{env_var} file" do
    expect(chef_run).to create_file("/opt/gitlab/etc/gitaly/#{env_var}").with_content(
      /#{content}/
    )
  end
end

shared_examples 'enabled registry env' do |env_var, content|
  it 'created env directory' do
    expect(chef_run).to create_directory("/opt/gitlab/etc/registry/env")
  end

  it "does create the #{env_var} file" do
    expect(chef_run).to create_file("/opt/gitlab/etc/registry/env/#{env_var}").with_content(
      /#{content}/
    )
  end
end

shared_examples 'enabled env' do |env_dir, env_var, content|
  it 'created env directory' do
    expect(chef_run).to create_directory(env_dir)
  end

  it "does create the #{env_var} file" do
    expect(chef_run).to create_file("#{env_dir}/#{env_var}").with_content(
      /#{content}/
    )
  end
end

shared_examples 'disabled env' do |env_dir, env_var, content|
  it 'created env directory' do
    expect(chef_run).to create_directory(env_dir)
  end

  it "does not create the #{env_var} file" do
    expect(chef_run).not_to create_file("#{env_dir}/#{env_var}").with_content(
      /#{content}/
    )
  end
end
