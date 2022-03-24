require 'chef_helper'

RSpec.describe 'gitlab::remote-syslog' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }
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
    before do
      stub_gitlab_rb(
        remote_syslog: {
          enable: true
        },
        logging: {
          udp_log_shipping_hostname: "example.com"
        }
      )
    end

    it 'creates the remote_syslog config' do
      expect(chef_run.node['gitlab']['remote-syslog']['enable']).to eq true
    end

    it 'creates remote-syslog config file with correct log directories' do
      expect(chef_run).to render_file('/var/opt/gitlab/remote-syslog/remote_syslog.yml')

      # Checking if log_directory of both type of services - those accessible
      # via node[service] and those via node['gitlab'][service] are populated.
      expect(chef_run).to render_file('/var/opt/gitlab/remote-syslog/remote_syslog.yml').with_content(/- \/var\/log\/gitlab\/redis\/\*.log/)
      expect(chef_run).to render_file('/var/opt/gitlab/remote-syslog/remote_syslog.yml').with_content(/- \/var\/log\/gitlab\/nginx\/\*.log/)
      expect(chef_run).to render_file('/var/opt/gitlab/remote-syslog/remote_syslog.yml').with_content(/- \/var\/log\/gitlab\/gitlab-rails\/\*.log/)
      expect(chef_run).to render_file('/var/opt/gitlab/remote-syslog/remote_syslog.yml').with_content(/- \/var\/log\/gitlab\/postgresql\/\*.log/)
      expect(chef_run).to render_file('/var/opt/gitlab/remote-syslog/remote_syslog.yml').with_content(/- \/var\/log\/gitlab\/sidekiq\/\*.log/)
      expect(chef_run).to render_file('/var/opt/gitlab/remote-syslog/remote_syslog.yml').with_content(/- \/var\/log\/gitlab\/gitlab-workhorse\/\*.log/)
      expect(chef_run).to render_file('/var/opt/gitlab/remote-syslog/remote_syslog.yml').with_content(/- \/var\/log\/gitlab\/gitlab-pages\/\*.log/)
      expect(chef_run).to render_file('/var/opt/gitlab/remote-syslog/remote_syslog.yml').with_content(/- \/var\/log\/gitlab\/gitlab-kas\/\*.log/)
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
