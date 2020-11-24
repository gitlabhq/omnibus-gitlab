require 'chef_helper'

RSpec.describe 'gitlab::logrotate_folder_and_configs_spec' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when logrotate is enabled' do
    it 'creates default set of directories' do
      expect(chef_run.node['logrotate']['dir'])
        .to eql('/var/opt/gitlab/logrotate')
      expect(chef_run.node['logrotate']['log_directory'])
        .to eql('/var/log/gitlab/logrotate')

      expect(chef_run).to create_directory('/var/opt/gitlab/logrotate').with(
        owner: nil,
        group: nil,
        mode: '0700'
      )
      expect(chef_run).to create_directory('/var/log/gitlab/logrotate').with(
        owner: nil,
        group: nil,
        mode: '0700'
      )
      expect(chef_run).to create_directory('/var/opt/gitlab/logrotate/logrotate.d').with(
        owner: nil,
        group: nil,
        mode: '0700'
      )
    end

    it 'creates logrotate directories in alternative locations' do
      stub_gitlab_rb(logrotate: { dir: "/tmp/logrotate", log_directory: "/tmp/logs/logrotate" })

      expect(chef_run).to create_directory('/tmp/logrotate').with(
        owner: nil,
        group: nil,
        mode: '0700'
      )
      expect(chef_run).to create_directory('/tmp/logs/logrotate').with(
        owner: nil,
        group: nil,
        mode: '0700'
      )
      expect(chef_run).to create_directory('/tmp/logrotate/logrotate.d').with(
        owner: nil,
        group: nil,
        mode: '0700'
      )
    end

    it 'creates default set of configuration templates' do
      expect(chef_run).to create_template('/var/opt/gitlab/logrotate/logrotate.d/nginx')
      expect(chef_run).to create_template('/var/opt/gitlab/logrotate/logrotate.d/unicorn')
      expect(chef_run).to create_template('/var/opt/gitlab/logrotate/logrotate.d/gitlab-rails')
      expect(chef_run).to create_template('/var/opt/gitlab/logrotate/logrotate.d/gitlab-shell')
      expect(chef_run).to create_template('/var/opt/gitlab/logrotate/logrotate.d/gitlab-workhorse')
      expect(chef_run).to create_template('/var/opt/gitlab/logrotate/logrotate.d/gitlab-pages')
      expect(chef_run).to create_template('/var/opt/gitlab/logrotate/logrotate.d/gitaly')
    end

    it 'populates configuration template with default values' do
      expect(chef_run).to render_file('/var/opt/gitlab/logrotate/logrotate.d/nginx')
        .with_content(/daily/)
      expect(chef_run).to render_file('/var/opt/gitlab/logrotate/logrotate.d/nginx')
        .with_content(/rotate 30/)
      expect(chef_run).to render_file('/var/opt/gitlab/logrotate/logrotate.d/nginx')
        .with_content(/compress/)
      expect(chef_run).to render_file('/var/opt/gitlab/logrotate/logrotate.d/nginx')
        .with_content(/copytruncate/)
      expect(chef_run).to render_file('/var/opt/gitlab/logrotate/logrotate.d/nginx')
        .with_content(/notifempty/)
      expect(chef_run).to render_file('/var/opt/gitlab/logrotate/logrotate.d/nginx')
        .with_content(/postrotate/)
      expect(chef_run).not_to render_file('/var/opt/gitlab/logrotate/logrotate.d/nginx')
        .with_content(/size/)
      expect(chef_run).not_to render_file('/var/opt/gitlab/logrotate/logrotate.d/nginx')
        .with_content(/maxsize/)
      expect(chef_run).not_to render_file('/var/opt/gitlab/logrotate/logrotate.d/nginx')
        .with_content(/dateext/)
    end

    it 'populates configuration template with custom values when logrotate is disabled' do
      stub_gitlab_rb(logging:
        { logrotate_frequency: "weekly",
          logrotate_size: "50",
          logrotate_maxsize: "50",
          logrotate_rotate: "50",
          logrotate_compress: "nocompress",
          logrotate_method: "copy",
          logrotate_postrotate: "/usr/bin/killall -HUP nginx",
          logrotate_dateformat: "-%Y-%m-%d", }, logrotate: { enable: false })

      expect(chef_run).to render_file('/var/opt/gitlab/logrotate/logrotate.d/nginx')
        .with_content(/weekly/)
      expect(chef_run).to render_file('/var/opt/gitlab/logrotate/logrotate.d/nginx')
        .with_content(/rotate 50/)
      expect(chef_run).to render_file('/var/opt/gitlab/logrotate/logrotate.d/nginx')
        .with_content(/nocompress/)
      expect(chef_run).to render_file('/var/opt/gitlab/logrotate/logrotate.d/nginx')
        .with_content(/copy/)
      expect(chef_run).to render_file('/var/opt/gitlab/logrotate/logrotate.d/nginx')
        .with_content(/postrotate/)
      expect(chef_run).to render_file('/var/opt/gitlab/logrotate/logrotate.d/nginx')
        .with_content(/size 50/)
      expect(chef_run).to render_file('/var/opt/gitlab/logrotate/logrotate.d/nginx')
        .with_content(/maxsize 50/)
      expect(chef_run).to render_file('/var/opt/gitlab/logrotate/logrotate.d/nginx')
        .with_content(/dateext/)
      expect(chef_run).to render_file('/var/opt/gitlab/logrotate/logrotate.d/nginx')
        .with_content(/dateformat -%Y-%m-%d/)
    end

    context 'when services not under gitlab key are specified' do
      it 'populates files correctly' do
        stub_gitlab_rb(
          logrotate: {
            services: ['gitlab-rails', 'gitaly']
          },
          gitaly: {
            log_directory: '/my/log/directory'
          }
        )
        expect(chef_run).to create_template('/var/opt/gitlab/logrotate/logrotate.d/gitlab-rails')
        expect(chef_run).to render_file('/var/opt/gitlab/logrotate/logrotate.d/gitaly')
          .with_content(/my\/log\/directory\/\*\.log/)
      end
    end

    context 'when services that are not supported are specified' do
      it 'raises an error' do
        stub_gitlab_rb(
          logrotate: {
            services: ['gitlab-rails', 'foo-bar']
          }
        )

        expect { chef_run }.to raise_error("Service foo-bar was specified in logrotate['services'], but is not a valid service.")
      end
    end
  end
end
