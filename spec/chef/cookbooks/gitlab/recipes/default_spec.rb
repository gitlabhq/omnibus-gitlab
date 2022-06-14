require 'chef_helper'

RSpec.describe 'gitlab::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  it 'creates the user config directory' do
    expect(chef_run).to create_directory('/etc/gitlab').with(
      user: 'root',
      group: 'root',
      mode: '0775'
    )
  end

  it 'creates the var opt data config directory' do
    expect(chef_run).to create_directory('Create /var/opt/gitlab').with(
      path: '/var/opt/gitlab',
      user: 'root',
      group: 'root',
      mode: '0755'
    )

    gitconfig_hash = {
      "receive" => ["fsckObjects = true", "advertisePushOptions = true"],
      "pack" => ["threads = 1"],
      "repack" => ["writeBitmaps = true"],
      "transfer" => ["hideRefs=^refs/tmp/", "hideRefs=^refs/keep-around/", "hideRefs=^refs/remotes/"],
      "core" => [
        'alternateRefsCommand="exit 0 #"',
        "fsyncObjectFiles = true"
      ],
      "fetch" => ["writeCommitGraph = true"]
    }

    expect(chef_run).to create_template('/opt/gitlab/embedded/etc/gitconfig').with(
      variables: { gitconfig: gitconfig_hash }
    )
  end

  it 'creates the system gitconfig directory and file' do
    stub_gitlab_rb(omnibus_gitconfig: { system: { receive: ["fsckObjects = true", "advertisePushOptions = true"], pack: ["threads = 2"] } })

    expect(chef_run).to create_directory('/opt/gitlab/embedded/etc').with(
      user: 'root',
      group: 'root',
      mode: '0755'
    )

    gitconfig_hash = {
      "receive" => ["fsckObjects = true", "advertisePushOptions = true"],
      "pack" => ["threads = 2"],
      "repack" => ["writeBitmaps = true"],
      "transfer" => ["hideRefs=^refs/tmp/", "hideRefs=^refs/keep-around/", "hideRefs=^refs/remotes/"],
      "core" => [
        'alternateRefsCommand="exit 0 #"',
        "fsyncObjectFiles = true"
      ],
      "fetch" => ["writeCommitGraph = true"]
    }

    expect(chef_run).to create_template('/opt/gitlab/embedded/etc/gitconfig').with(
      source: 'gitconfig-system.erb',
      variables: { gitconfig: gitconfig_hash },
      mode: 0755
    )
  end

  context 'with logrotate' do
    it 'runs logrotate directory and configuration recipe by default' do
      expect(chef_run).to include_recipe('logrotate::folders_and_configs')
    end

    it 'runs logrotate directory and configuration recipe when logrotate is disabled' do
      stub_gitlab_rb(logrotate: { enable: false })

      expect(chef_run).to include_recipe('logrotate::folders_and_configs')
    end
  end

  context 'when manage_etc directory management is disabled' do
    before { stub_gitlab_rb(manage_storage_directories: { enable: true, manage_etc: false }) }

    it 'does not create the user config directory' do
      expect(chef_run).not_to create_directory('/etc/gitlab')
    end
  end

  context 'prometheus is enabled by default' do
    it 'includes the prometheus recipe' do
      expect(chef_run).to include_recipe('monitoring::prometheus')
      expect(chef_run).not_to include_recipe('monitoring::prometheus_disable')
    end
  end

  context 'with prometheus disabled' do
    before { stub_gitlab_rb(prometheus: { enable: false }) }

    it 'includes the prometheus_disable recipe' do
      expect(chef_run).to include_recipe('monitoring::prometheus_disable')
      expect(chef_run).not_to include_recipe('monitoring::prometheus')
    end
  end

  context 'with database reindexing and LetsEncrypt auto-renew disabled' do
    it 'disables crond' do
      expect(chef_run).to include_recipe('crond::disable')
      expect(chef_run).not_to include_recipe('crond::enable')
    end
  end

  context 'with database reindexing enabled' do
    before do
      stub_gitlab_rb(gitlab_rails: { database_reindexing: { enable: true } })
    end

    it 'enables crond' do
      expect(chef_run).to include_recipe('crond::enable')
      expect(chef_run).not_to include_recipe('crond::disable')
    end
  end

  context 'with LetsEncrypt auto-renew enabled' do
    before do
      # Registry will be auto-enabled if LetsEncrypt is enabled
      stub_gitlab_rb(external_url: 'http://gitlab.example.com',
                     registry: { enable: false },
                     letsencrypt: { enable: true, auto_renew: true })
    end

    it 'enables crond' do
      expect(chef_run).to include_recipe('crond::enable')
      expect(chef_run).not_to include_recipe('crond::disable')
    end
  end

  shared_examples 'consistent exporter TLS settings' do |target|
    context 'when TLS is enabled' do
      context 'when certificate path is blank' do
        let(:exporter_settings) do
          {
            exporter_tls_enabled: true,
            exporter_tls_key_path: '/valid/path'
          }
        end

        it 'raises an error' do
          expect { chef_run }.to raise_error(/#{target} exporter_tls_enabled is true, but exporter_tls_cert_path is not set/)
        end
      end

      context 'when key path is blank' do
        let(:exporter_settings) do
          {
            exporter_tls_enabled: true,
            exporter_tls_cert_path: '/valid/path'
          }
        end

        it 'raises an error' do
          expect { chef_run }.to raise_error(/#{target} exporter_tls_enabled is true, but exporter_tls_key_path is not set/)
        end
      end
    end

    context 'when TLS is disabled' do
      let(:exporter_settings) do
        {
          exporter_tls_enabled: false
        }
      end

      it 'does not raise an error' do
        expect { chef_run }.not_to raise_error
      end
    end
  end

  context 'with dedicated Puma exporter settings' do
    context 'when exporter is enabled' do
      let(:puma_settings) do
        {
          exporter_enabled: true
        }
      end

      let(:exporter_settings) { {} }

      before do
        stub_gitlab_rb(puma: puma_settings.merge(exporter_settings))
      end

      it_behaves_like 'consistent exporter TLS settings', 'Puma'
    end
  end

  context 'with dedicated Sidekiq exporter settings' do
    context 'when exporter is enabled' do
      let(:sidekiq_settings) do
        {
          metrics_enabled: true
        }
      end

      let(:exporter_settings) { {} }

      before do
        stub_gitlab_rb(sidekiq: sidekiq_settings.merge(exporter_settings))
      end

      it_behaves_like 'consistent exporter TLS settings', 'Sidekiq'
    end

    context 'when exporter is not enabled' do
      before do
        stub_gitlab_rb(
          sidekiq:
            {
              metrics_enabled: false,
              listen_address: 'localhost',
              listen_port: 3807,
              health_checks_enabled: true,
              health_checks_listen_address: '127.0.0.1',
              health_checks_listen_port: 3807
            }
        )
      end

      it 'does not raise an error' do
        expect { chef_run }.not_to raise_error
      end
    end

    context 'when Sidekiq health checks is not enabled' do
      before do
        stub_gitlab_rb(
          sidekiq:
            {
              metrics_enabled: true,
              listen_address: 'localhost',
              listen_port: 3807,
              health_checks_enabled: false,
              health_checks_listen_address: '127.0.0.1',
              health_checks_listen_port: 3807
            }
        )
      end

      it 'does not raise an error' do
        expect { chef_run }.not_to raise_error
      end
    end

    context 'when both Sidekiq exporter and Sidekiq health checks are enabled' do
      context 'when Sidekiq exporter and Sidekiq health checks addresses are both loopback addresses and the ports are the same' do
        before do
          stub_gitlab_rb(
            sidekiq:
              {
                metrics_enabled: true,
                listen_address: 'localhost',
                listen_port: 3807,
                health_checks_enabled: true,
                health_checks_listen_address: '127.0.0.1',
                health_checks_listen_port: 3807
              }
          )
        end

        it 'raises an error' do
          expect { chef_run }.to raise_error("The Sidekiq metrics and health checks servers are binding the same address and port. This is unsupported in GitLab 15.0 and newer. See https://docs.gitlab.com/ee/administration/sidekiq.html for up-to-date instructions.")
        end
      end

      context 'when Sidekiq exporter and Sidekiq health checks port are the same' do
        before do
          stub_gitlab_rb(
            sidekiq:
              {
                metrics_enabled: true,
                listen_address: 'localhost',
                listen_port: 3807,
                health_checks_enabled: true,
                health_checks_listen_address: 'localhost',
                health_checks_listen_port: 3807
              }
          )
        end

        it 'raises an error' do
          expect { chef_run }.to raise_error("The Sidekiq metrics and health checks servers are binding the same address and port. This is unsupported in GitLab 15.0 and newer. See https://docs.gitlab.com/ee/administration/sidekiq.html for up-to-date instructions.")
        end
      end

      context 'when Sidekiq exporter and Sidekiq health checks port are different' do
        before do
          stub_gitlab_rb(
            sidekiq:
              {
                metrics_enabled: true,
                listen_address: 'localhost',
                listen_port: 3807,
                health_checks_enabled: true,
                health_checks_listen_address: 'localhost',
                health_checks_listen_port: 3907
              }
          )
        end

        it 'does not raise an error' do
          expect { chef_run }.not_to raise_error
        end
      end
    end
  end

  context 'with sidekiq exporter settings not set (default settings)' do
    it 'does not raise an error' do
      expect { chef_run }.not_to raise_error
    end
  end
end
