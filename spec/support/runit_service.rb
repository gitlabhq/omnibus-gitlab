shared_examples 'runit service' do |svc_name, owner, group|
  it 'creates directories' do
    expect(chef_run).to create_directory("/opt/gitlab/sv/#{svc_name}").with(
      owner: owner,
      group: group,
      mode: 493 # 0755 is an octal value. 493 is the decimal conversion.
    )
    expect(chef_run).to create_directory("/opt/gitlab/sv/#{svc_name}/log").with(
      owner: owner,
      group: group,
      mode: 493 # 0755 is an octal value. 493 is the decimal conversion.
    )
    expect(chef_run).to create_directory("/opt/gitlab/sv/#{svc_name}/log/main").with(
      owner: owner,
      group: group,
      mode: 493 # 0755 is an octal value. 493 is the decimal conversion.
    )
  end

  it 'creates files' do
    expect(chef_run).to create_template("/opt/gitlab/sv/#{svc_name}/run")
    expect(chef_run).to render_file("/opt/gitlab/sv/#{svc_name}/log/run")
    expect(chef_run).to render_file("/var/log/gitlab/#{svc_name}/config")

    expect(chef_run).to create_template("/opt/gitlab/sv/#{svc_name}/run").with(
      owner: owner,
      group: group,
      mode: 493 # 0755 is an octal value. 493 is the decimal conversion.
    )
    expect(chef_run).to create_template("/opt/gitlab/sv/#{svc_name}/log/run").with(
      owner: owner,
      group: group,
      mode: 493 # 0755 is an octal value. 493 is the decimal conversion.
    )
    expect(chef_run).to create_template("/var/log/gitlab/#{svc_name}/config").with(
      owner: owner,
      group: group,
      mode: nil # 0755 is an octal value. 493 is the decimal conversion.
    )
  end

  it 'creates the symlink to the service directory' do
    expect(chef_run).to create_link("/opt/gitlab/init/#{svc_name}").with(to: '/opt/gitlab/embedded/bin/sv')
  end
end
