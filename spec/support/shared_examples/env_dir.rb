shared_examples 'enabled service env' do |service, env_var, content|
  it 'created env directory' do
    expect(chef_run).to create_directory("/opt/gitlab/etc/#{service}/env")
  end

  it "does create the #{env_var} file" do
    expect(chef_run).to create_file("/opt/gitlab/etc/#{service}/env/#{env_var}").with_content(
      /#{content}/
    )
  end
end

shared_examples 'disabled service env' do |service, env_var, content|
  it 'created env directory' do
    expect(chef_run).to create_directory("/opt/gitlab/etc/#{service}/env")
  end

  it "does not create the #{env_var} file" do
    expect(chef_run).not_to create_file("/opt/gitlab/etc/#{service}/env/#{env_var}").with_content(
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
