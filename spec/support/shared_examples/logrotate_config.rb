shared_examples 'configured logrotate service' do |svc, username = 'git', group = 'git'|
  it 'creates logrotate config file' do
    expect(chef_run).to render_file("/var/opt/gitlab/logrotate/logrotate.d/#{svc}")
  end

  it 'specifies su parameter in logrotate config' do
    expect(chef_run).to render_file("/var/opt/gitlab/logrotate/logrotate.d/#{svc}").with_content(/su #{username} #{group}/)
  end
end
