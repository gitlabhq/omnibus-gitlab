require 'spec_helper'

RSpec.describe Gitlab::Deprecations do
  let(:valid_config) { { gitlab: { nginx: { listen_addresses: "SomeRandomString" } } } }
  let(:invalid_config) do
    {
      "gitlab" => {
        "nginx" => {
          "listen_address" => "SomeRandomString"
        },
        "gitlab-rails" => {
          "stuck_ci_builds_worker_cron" => "5 * * * *"
        }
      },
      "mattermost" => {
        "system_read_timeout" => 50,
        "log_file_directory" => "/my/random/path"
      },
      "monitoring" => {
        "gitlab-monitor" => {
          "enable" => false
        }
      }
    }
  end

  let(:conf1) do
    {
      config_keys: %w(gitlab nginx listen_address),
      deprecation: '8.10',
      removal: '11.0',
      note: "Use nginx['listen_addresses'] instead."
    }
  end

  let(:conf2) do
    {
      config_keys: %w(gitlab gitlab-rails stuck_ci_builds_worker_cron),
      deprecation: '9.0',
      removal: '12.0',
      note: "Use gitlab_rails['stuck_ci_jobs_worker_cron'] instead."
    }
  end

  let(:conf3) do
    {
      config_keys: %w(gitlab gitlab-shell git_data_directories),
      deprecation: '8.10',
      removal: '11.0',
      note: "Use git_data_dirs instead."
    }
  end

  let(:conf4) do
    {
      config_keys: %w(monitoring gitlab-monitor enable),
      deprecation: '12.0',
      removal: '13.0',
      note: "Use gitlab_exporter['enable'] instead."
    }
  end

  let(:deprecation_list) do
    [
      conf1,
      conf2,
      conf3,
      conf4,
    ]
  end

  before(:each) do
    allow(Gitlab::Deprecations).to receive(:list).and_return(deprecation_list)
  end

  describe '.applicable_deprecations' do
    it 'detects valid configuration' do
      expect(described_class.applicable_deprecations("11.0", valid_config, :deprecation)).to eq([])
    end

    it 'distinguishes from deprecated and removed configuration' do
      expect(described_class.applicable_deprecations("11.0", invalid_config, :deprecation)).to include(conf1)
      expect(described_class.applicable_deprecations("11.0", invalid_config, :deprecation)).to include(conf2)
      expect(described_class.applicable_deprecations("12.0", invalid_config, :deprecation)).to include(conf1)
      expect(described_class.applicable_deprecations("12.0", invalid_config, :deprecation)).to include(conf2)

      expect(described_class.applicable_deprecations("11.0", invalid_config, :removal)).not_to include(conf2)
      expect(described_class.applicable_deprecations("12.0", invalid_config, :removal)).to include(conf2)
    end

    it 'also detects deprecated falsey values' do
      expect(described_class.applicable_deprecations("12.0", invalid_config, :deprecation)).to include(conf4)
    end
  end

  describe '.check_config' do
    it 'detects valid_config configuration' do
      expect(described_class.check_config("11.0", valid_config)).to eq([])
    end

    it 'detects deprecated configuration for specified version and ignores not yet deprecated ones' do
      message_1 = "* nginx['listen_address'] has been deprecated since 8.10 and was removed in 11.0. Use nginx['listen_addresses'] instead."
      message_2 = "* gitlab_rails['stuck_ci_builds_worker_cron'] has been deprecated since 9.0 and was removed in 12.0. Use gitlab_rails['stuck_ci_jobs_worker_cron'] instead."
      message_3 = "* gitlab_monitor['enable'] has been deprecated since 12.0 and will be removed in 13.0. Use gitlab_exporter['enable'] instead."

      expect(described_class.check_config("11.0", invalid_config)).to include(message_1)
      expect(described_class.check_config("11.0", invalid_config)).not_to include(message_2)
      expect(described_class.check_config("12.0", invalid_config)).to include(message_2)
      expect(described_class.check_config("12.0", invalid_config, :deprecation)).to include(message_3)
    end
  end

  describe '.identify_deprecated_config' do
    it 'detects deprecations correctly from list of supported keys' do
      mattermost_supported_keys = %w(log_file_directory)
      output = [
        {
          config_keys: %w(mattermost system_read_timeout),
          deprecation: '10.2',
          removal: '11.0',
          note: nil
        }
      ]
      expect(described_class.identify_deprecated_config(invalid_config, ["mattermost"], mattermost_supported_keys, "10.2", "11.0")).to eq(output)
    end
  end

  describe '.deprecate_only_if_value' do
    let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

    before do
      allow(Gitlab).to receive(:[]).and_call_original
    end

    context 'during removals' do
      context 'when deprecated config is not set' do
        it 'does not raise warning' do
          expect(described_class.deprecate_only_if_value('14.0', chef_run.node.normal, :removal, ['gitlab', 'puma'], 'enable', true, '13.10', '14.0')).to eq([])
        end
      end

      context 'when deprecated config is set to an acceptable value' do
        before do
          stub_gitlab_rb(
            puma: { enable: false }
          )
        end
        it 'does not raise warning' do
          expect(described_class.deprecate_only_if_value('14.0', chef_run.node.normal, :removal, ['gitlab', 'puma'], 'enable', true, '13.10', '14.0')).to eq([])
        end
      end

      context 'when deprecated config is set to an unacceptable value' do
        before do
          stub_gitlab_rb(
            puma: { enable: true }
          )
        end
        it 'raises warning' do
          expect(described_class.deprecate_only_if_value('14.0', chef_run.node.normal, :removal, ['gitlab', 'puma'], 'enable', true, '13.10', '14.0')).to eq(["* puma[enable] has been deprecated since 13.10 and was removed in 14.0."])
        end
      end
    end

    context 'during deprecations' do
      context 'when deprecated config is not set' do
        it 'does not raise warning' do
          expect(described_class.deprecate_only_if_value('13.12', chef_run.node.normal, :deprecation, ['gitlab', 'puma'], 'enable', true, '13.10', '14.0')).to eq([])
        end
      end

      context 'when deprecated config is set to an acceptable value' do
        before do
          stub_gitlab_rb(
            puma: { enable: false }
          )
        end
        it 'raises warning' do
          expect(described_class.deprecate_only_if_value('13.12', chef_run.node.normal, :deprecation, ['gitlab', 'puma'], 'enable', true, '13.10', '14.0')).to eq(["* puma[enable] has been deprecated since 13.10 and will be removed in 14.0."])
        end
      end

      context 'when deprecated config is set to an unacceptable value' do
        before do
          stub_gitlab_rb(
            puma: { enable: true }
          )
        end
        it 'raises warning' do
          expect(described_class.deprecate_only_if_value('13.12', chef_run.node.normal, :deprecation, ['gitlab', 'puma'], 'enable', true, '13.10', '14.0')).to eq(["* puma[enable] has been deprecated since 13.10 and will be removed in 14.0."])
        end
      end
    end
  end

  describe 'NodeAttribute' do
    before do
      Gitlab::Deprecations::NodeAttribute.log_deprecations = true
    end

    after do
      Gitlab::Deprecations::NodeAttribute.log_deprecations = false
    end

    it 'Logs deprecations for passed variables and proxies to new object' do
      config = { 'monitoring' => { 'test' => 'test-value' } }
      config['prometheus'] = Gitlab::Deprecations::NodeAttribute.new(config['monitoring'], "config['prometheus']", "config['monitoring']")

      expect(config['prometheus']['test']).to eq('test-value')
      expect_logged_deprecation(/Accessing config\['prometheus'\] is deprecated/)
    end

    it 'Logs deprecations for passed variables and proxies to new Proc if provided' do
      config = { 'monitoring' => { 'test' => 'test-value' } }
      config['prometheus'] = Gitlab::Deprecations::NodeAttribute.new(proc { config['monitoring'] }, "config['prometheus']", "config['monitoring']")

      expect(config['prometheus']['test']).to eq('test-value')
      expect_logged_deprecation(/Accessing config\['prometheus'\] is deprecated/)
    end
  end
end
