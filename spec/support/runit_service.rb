def get_env_string(username, groupname)
  env_string = ""
  env_string << username if username
  env_string << ":#{groupname}" if groupname

  env_string
end

shared_examples 'enabled runit service' do |svc_name, owner, group, username = nil, groupname = nil|
  it 'creates directories' do
    expect(chef_run).to create_directory("/opt/gitlab/sv/#{svc_name}").with(
      owner: owner,
      group: group,
      mode: '0755'
    )
    expect(chef_run).to create_directory("/opt/gitlab/sv/#{svc_name}/log").with(
      owner: owner,
      group: group,
      mode: '0755'
    )
    expect(chef_run).to create_directory("/opt/gitlab/sv/#{svc_name}/log/main").with(
      owner: owner,
      group: group,
      mode: '0755'
    )
  end

  it 'creates files' do
    expect(chef_run).to create_template("/opt/gitlab/sv/#{svc_name}/run").with(
      owner: owner,
      group: group,
      mode: '0755'
    )
    expect(chef_run).to create_template("/opt/gitlab/sv/#{svc_name}/log/run").with(
      owner: owner,
      group: group,
      mode: '0755'
    )
    expect(chef_run).to create_template("/var/log/gitlab/#{svc_name}/config").with(
      owner: owner,
      group: group,
      mode: '0644'
    )

    env_string = get_env_string(username, groupname)

    if env_string.empty?
      expect(chef_run).to render_file("/opt/gitlab/sv/#{svc_name}/run").with_content(%r{.*})
    else
      expect(chef_run).to render_file("/opt/gitlab/sv/#{svc_name}/run").with_content(/-u #{env_string}/)
      expect(chef_run).to render_file("/opt/gitlab/sv/#{svc_name}/run").with_content(/-U #{env_string}/)
    end

    expect(chef_run).to render_file("/opt/gitlab/sv/#{svc_name}/log/run").with_content(%r{.*})
    expect(chef_run).to render_file("/var/log/gitlab/#{svc_name}/config").with_content(%r{.*})
  end

  it 'verifies that file ownership persists' do
    expect(chef_run.template("/var/log/gitlab/#{svc_name}/config")).to notify("ruby_block[verify_chown_persisted_on_#{svc_name}]")
  end

  it 'raises an error when file ownership does not persist' do
    allow_any_instance_of(OmnibusHelper).to receive(:expected_user?).and_return(true)
    allow_any_instance_of(OmnibusHelper).to receive(:expected_user?).with(/\/var\/log\/gitlab\/.*\/config/, anything).and_return(false)

    allow_any_instance_of(OmnibusHelper).to receive(:expected_group?).and_return(true)
    allow_any_instance_of(OmnibusHelper).to receive(:expected_group?).with(/\/var\/log\/gitlab\/.*\/config/, anything).and_return(false)

    block = chef_run.find_resource('ruby_block', "verify_chown_persisted_on_#{svc_name}")
    expect { block.block.call }.to raise_error("Unable to persist filesystem ownership changes of /var/log/gitlab/#{svc_name}/config. See https://docs.gitlab.com/ee/administration/high_availability/nfs.html#recommended-options for guidance.")
  end

  it 'creates the symlink to the service directory' do
    expect(chef_run).to create_link("/opt/gitlab/init/#{svc_name}").with(to: '/opt/gitlab/embedded/bin/sv')
  end
end

shared_examples 'disabled runit service' do |svc_name|
  it 'does not create directories' do
    expect(chef_run).not_to create_directory("/opt/gitlab/sv/#{svc_name}")
    expect(chef_run).not_to create_directory("/opt/gitlab/sv/#{svc_name}/log")
    expect(chef_run).not_to create_directory("/opt/gitlab/sv/#{svc_name}/log/main")
  end

  it 'does not create files' do
    expect(chef_run).not_to create_template("/opt/gitlab/sv/#{svc_name}/run")
    expect(chef_run).not_to create_template("/opt/gitlab/sv/#{svc_name}/log/run")
    expect(chef_run).not_to create_template("/var/log/gitlab/#{svc_name}/config")
  end

  it 'runs the disable service ruby block' do
    allow_any_instance_of(Chef::Provider::RunitService).to receive(:enabled?).and_return(true)
    expect(chef_run).to run_ruby_block("disable #{svc_name}")
  end
end
