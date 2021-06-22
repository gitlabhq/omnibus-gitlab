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
end
