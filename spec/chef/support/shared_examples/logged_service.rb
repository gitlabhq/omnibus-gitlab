RSpec.shared_examples 'enabled logged service' do |svc_name, is_runit = false, settings = {}|
  log_directory = settings[:log_directory] || "/var/log/gitlab/#{svc_name}"
  expected_log_dir_owner = settings[:log_directory_owner] || 'root'
  expected_log_dir_group = settings[:log_group] || settings[:log_directory_group] || nil
  default_log_dir_mode = expected_log_dir_group.nil? ? '0700' : '0750'
  expected_log_dir_mode = settings[:log_directory_mode] || default_log_dir_mode
  expected_runit_owner = settings[:runit_owner] || 'root'
  expected_runit_group = settings[:log_group] || settings[:runit_group] || 'root'

  it 'creates expected log directories with correct permissions' do
    expect(chef_run).to create_directory(log_directory).with(
      user: expected_log_dir_owner,
      group: expected_log_dir_group,
      mode: expected_log_dir_mode
    )
  end

  if is_runit
    it 'creates the runit log/run file using chpst to run as the expected user and group' do
      log_run_with_chpst = Regexp.new([
        %r{#!/bin/sh},
        %r{exec chpst -P \\},
        %r{  -U #{expected_runit_owner}:#{expected_runit_group} \\},
        %r{  -u #{expected_runit_owner}:#{expected_runit_group} \\},
        %r{  svlogd (.*)},
      ].map(&:to_s).join('\n'))

      expect(chef_run).to render_file("/opt/gitlab/sv/#{svc_name}/log/run").with_content { |content|
        expect(content).to match(log_run_with_chpst)
      }
    end
  end
end
