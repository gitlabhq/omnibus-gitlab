require 'chef_helper'

describe 'gitlab::remote-syslog' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'creates service' do
    before do
      stub_gitlab_rb(
        remote_syslog: {
          enable: true
        }
      )
    end
    it_behaves_like "enabled runit service", "remote-syslog", "root", "root"
  end

  context 'when remote logger is enabled' do
    it 'creates the remote_syslog config' do
      stub_gitlab_rb(
        remote_syslog: {
          enable: true
        },
        logging: {
          udp_log_shipping_hostname: "example.com"
        }
      )
      expect(chef_run.node['gitlab']['remote-syslog']['enable']).to eq true
      expect(chef_run).to render_file('/var/opt/gitlab/remote-syslog/remote_syslog.yml')
    end

    it 'creates the remote-syslog sv file without setting hostname' do
      stub_gitlab_rb(
        remote_syslog: {
          enable: true
        }
      )
      contents = <<~END
      #!/bin/sh
      exec 2>&1

      exec /opt/gitlab/embedded/bin/remote_syslog --no-detach --debug-level DEBUG -c /var/opt/gitlab/remote-syslog/remote_syslog.yml
      END
      expect(chef_run).to render_file('/opt/gitlab/sv/remote-syslog/run').with_content(contents.chomp)
    end

    it 'creates the remote-syslog sv file with setting hostname' do
      stub_gitlab_rb(
        remote_syslog: {
          enable: true
        },
        logging: {
          udp_log_shipping_hostname: "example.com"
        }
      )
      contents = <<~END
      #!/bin/sh
      exec 2>&1

      exec /opt/gitlab/embedded/bin/remote_syslog --no-detach --debug-level DEBUG -c /var/opt/gitlab/remote-syslog/remote_syslog.yml --hostname example.com
      END
      expect(chef_run).to render_file('/opt/gitlab/sv/remote-syslog/run').with_content(contents.chomp)
    end
  end
end
