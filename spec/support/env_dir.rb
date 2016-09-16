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
    expect(chef_run).to_not create_file("/opt/gitlab/etc/gitlab-rails/env/#{env_var}").with_content(
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
