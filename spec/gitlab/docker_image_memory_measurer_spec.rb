require 'spec_helper'
require 'gitlab/docker_image_memory_measurer'

describe Gitlab::DockerImageMemoryMeasurer do
  let(:image_reference) { 'mocked_image_reference' }
  let(:measurer) { described_class.new(image_reference, debug_output_dir) }
  let(:delete_debug_output_dir) { FileUtils.remove_dir(debug_output_dir, true) }
  let(:create_debug_output_dir) { FileUtils.mkdir_p(debug_output_dir) unless debug_output_dir.nil? }

  before(:each) do
    create_debug_output_dir
  end

  after(:each) do
    delete_debug_output_dir
  end

  describe '.new' do
    context 'debug_output_dir is specified' do
      let(:debug_output_dir) { 'tmp/measure_log_folder' }

      it 'set debug output file names' do
        expect(measurer.container_log_file).to eq('tmp/measure_log_folder/container_setup.log')
        expect(measurer.pid_command_map_file).to eq('tmp/measure_log_folder/pid_command_map.txt')
        expect(measurer.smem_result_file).to eq('tmp/measure_log_folder/smem_result.txt')
      end
    end

    context 'debug_output_dir is not specified' do
      let(:debug_output_dir) { nil }

      it 'set debug output file names' do
        expect(measurer.container_log_file).to be_nil
        expect(measurer.pid_command_map_file).to be_nil
        expect(measurer.smem_result_file).to be_nil
      end
    end
  end

  describe '.check_url' do
    let(:debug_output_dir) { nil }

    it 'pass through the return value' do
      result = measurer.check_url do
        'value'
      end

      expect(result).to eq('value')
    end

    context 'when yield raise StandardError' do
      let(:raise_exception_in_yield) do
        measurer.check_url do
          raise StandardError
        end
      end

      it 'return false' do
        expect(raise_exception_in_yield).to be false
      end
    end
  end

  describe '.check_url_alive' do
    let(:debug_output_dir) { nil }
    let(:url) { 'url' }

    it 'return true when HTTP return code 200' do
      expect(HTTP).to receive(:get).with(url)
      allow(HTTP).to receive_message_chain(:get, :code).and_return(200)

      expect(measurer.check_url_alive(url)).to be true
    end

    it 'return false when HTTP return code 502' do
      expect(HTTP).to receive(:get).with(url)
      allow(HTTP).to receive_message_chain(:get, :code).and_return(502)

      expect(measurer.check_url_alive(url)).to be false
    end

    it 'return false when HTTP throw StandardError' do
      expect(HTTP).to receive(:get).with(url).and_raise(StandardError)

      expect(measurer.check_url_alive(url)).to be false
    end
  end

  describe '.legacy_readiness_format_status_ok?' do
    let(:debug_output_dir) { nil }

    context 'given non hash value' do
      let(:hash) { nil }

      it 'return false' do
        expect(measurer.legacy_readiness_format_status_ok?(hash)).to be false
      end
    end

    context 'given empty hash' do
      let(:hash) { {} }

      it 'return false' do
        expect(measurer.legacy_readiness_format_status_ok?(hash)).to be false
      end
    end

    context 'given valid hash with all status ok' do
      let(:hash) { { 'db_check' => { 'status' => 'ok' }, 'redis_check' => { 'status' => 'ok' } } }

      it 'return true' do
        expect(measurer.legacy_readiness_format_status_ok?(hash)).to be true
      end
    end

    context 'given valid hash with one status not ok' do
      let(:hash) { { 'db_check' => { 'status' => 'failed' }, 'redis_check' => { 'status' => 'ok' } } }

      it 'return false' do
        expect(measurer.legacy_readiness_format_status_ok?(hash)).to be false
      end
    end
  end

  describe '.new_readiness_format_status_ok?' do
    let(:debug_output_dir) { nil }

    context 'given non hash value' do
      let(:hash) { nil }

      it 'return false' do
        expect(measurer.new_readiness_format_status_ok?(hash)).to be false
      end
    end

    context 'given empty hash' do
      let(:hash) { {} }

      it 'return false' do
        expect(measurer.new_readiness_format_status_ok?(hash)).to be false
      end
    end

    context 'given hash missing status' do
      let(:hash) { { 'master_check' => [{ 'status' => 'ok' }] } }

      it 'return false' do
        expect(measurer.new_readiness_format_status_ok?(hash)).to be false
      end
    end

    context 'given hash missing master check status' do
      let(:hash) { { 'status' => 'ok' } }

      it 'return false' do
        expect(measurer.new_readiness_format_status_ok?(hash)).to be false
      end
    end

    context 'given valid hash with all status ok' do
      let(:hash) { { 'status' => 'ok', 'master_check' => [{ 'status' => 'ok' }] } }

      it 'return true' do
        expect(measurer.new_readiness_format_status_ok?(hash)).to be true
      end
    end

    context 'given valid hash with status not ok' do
      let(:hash) { { 'status' => 'failed', 'master_check' => [{ 'status' => 'ok' }] } }

      it 'return false' do
        expect(measurer.new_readiness_format_status_ok?(hash)).to be false
      end
    end

    context 'given valid hash with master check status not ok' do
      let(:hash) { { 'status' => 'ok', 'master_check' => [{ 'status' => 'failed' }] } }

      it 'return false' do
        expect(measurer.new_readiness_format_status_ok?(hash)).to be false
      end
    end
  end

  describe '.status_ok?' do
    let(:debug_output_dir) { nil }

    it 'returns true with successful legacy format status check' do
      allow(measurer).to receive(:legacy_readiness_format_status_ok?).and_return(true)
      allow(measurer).to receive(:new_readiness_format_status_ok?).and_return(false)

      expect(measurer.status_ok?(hash)).to be true
    end

    it 'returns true with successful new format status check' do
      allow(measurer).to receive(:legacy_readiness_format_status_ok?).and_return(false)
      allow(measurer).to receive(:new_readiness_format_status_ok?).and_return(true)

      expect(measurer.status_ok?(hash)).to be true
    end

    it 'returns false when both new and legacy format status check fail' do
      allow(measurer).to receive(:legacy_readiness_format_status_ok?).and_return(false)
      allow(measurer).to receive(:new_readiness_format_status_ok?).and_return(false)

      expect(measurer.status_ok?(hash)).to be false
    end
  end

  describe '.check_gitlab_ready' do
    let(:debug_output_dir) { nil }
    let(:url) { 'url' }
    let(:http_return) { 'http_return' }
    let(:response) { 'response' }
    let(:status_ok_return) { 'status_ok_return' }

    it 'return whatever new_readiness_format_status_ok? result' do
      expect(HTTP).to receive(:get).with(url).and_return(http_return)
      allow(JSON).to receive(:parse).with(http_return).and_return(response)
      expect(measurer).to receive(:status_ok?).with(response).and_return(status_ok_return)

      expect(measurer.check_gitlab_ready(url)).to eq(status_ok_return)
    end

    it 'return false when HTTP throw StandardError' do
      expect(HTTP).to receive(:get).with(url).and_raise(StandardError)

      expect(measurer.check_gitlab_ready(url)).to be false
    end

    it 'return false when JSON throw StandardError' do
      expect(HTTP).to receive(:get).with(url).and_return(http_return)
      allow(JSON).to receive(:parse).with(http_return).and_raise(StandardError)

      expect(measurer.check_gitlab_ready(url)).to be false
    end
  end

  describe '.container_exec_command' do
    let(:debug_output_dir) { 'tmp/measure' }
    let(:container) { double }
    let(:command) { 'ls' }
    let(:log_file) { 'tmp/measure/log_file.txt' }

    context 'command succeed' do
      it 'return the stdout result' do
        expect(container).to receive(:exec).with(command, wait: 120).and_return([%w[success message], [], 0])
        command_ret = measurer.container_exec_command(container, command, log_file, 120)
        expect(command_ret).to eq('successmessage')
      end
    end

    context 'command fail' do
      it 'should raise error' do
        expect(container).to receive(:exec).with(command, wait: 120).and_return([[], %w[error message], 1])
        expect { measurer.container_exec_command(container, command, log_file, 120) }.to raise_error(SystemExit, 'errormessage')
      end
    end
  end

  describe '.stdout_to_hash_array' do
    let(:debug_output_dir) { nil }

    context 'use customised separator' do
      let(:stdout) do
        <<-STDOUTSTRING
           PID<Pid_Command_Separator>COMMAND
           1<Pid_Command_Separator>/bin/bash /assets/wrapper
           23<Pid_Command_Separator>runsv sshd
           24<Pid_Command_Separator>svlogd -tt /var/log/gitlab/sshd
        STDOUTSTRING
      end
      let(:separator) { /<Pid_Command_Separator>/ }
      let(:expected_ret) do
        [
          { 'PID' => '1', 'COMMAND' => '/bin/bash /assets/wrapper' },
          { 'PID' => '23', 'COMMAND' => 'runsv sshd' },
          { 'PID' => '24', 'COMMAND' => 'svlogd -tt /var/log/gitlab/sshd' }
        ]
      end

      it 'return hash array' do
        expect(measurer.stdout_to_hash_array(stdout, separator)).to eq(expected_ret)
      end
    end

    context 'use space as separator' do
      let(:stdout) do
        <<-STDOUTSTRING
           PID User     Swap      USS      PSS      RSS     Command
           316 git      3504      432      443     1452     /opt/gitlab/embedded/bin/gi
           312 git       148      240      523     2476     /bin/bash /opt/gitlab/embed
        STDOUTSTRING
      end
      let(:separator) { /\s+/ }
      let(:expected_ret) do
        [
          { 'PID' => '316', 'User' => 'git', 'Command' => '/opt/gitlab/embedded/bin/gi', 'Swap' => '3504', 'USS' => '432', 'PSS' => '443', 'RSS' => '1452' },
          { 'PID' => '312', 'User' => 'git', 'Command' => '/bin/bash', 'Swap' => '148', 'USS' => '240', 'PSS' => '523', 'RSS' => '2476' }
        ]
      end

      it 'return hash array' do
        expect(measurer.stdout_to_hash_array(stdout, separator)).to eq(expected_ret)
      end
    end

    context 'give empty stdout' do
      let(:stdout) do
        <<-STDOUTSTRING
           PID<Pid_Command_Separator>COMMAND
        STDOUTSTRING
      end
      let(:separator) { /<Pid_Command_Separator>/ }
      let(:expected_ret) { [] }

      it 'return hash array' do
        expect(measurer.stdout_to_hash_array(stdout, separator)).to eq(expected_ret)
      end
    end
  end

  describe '.find_component' do
    let(:debug_output_dir) { nil }
    let(:component_command_patterns) { { 'c1' => /p1/, 'c2' => /p2/, 'c3' => /p3/ } }

    context 'command match exactly one pattern' do
      let(:command) { 'p1' }

      it 'return the component name' do
        allow(measurer).to receive(:component_command_patterns).and_return(component_command_patterns)
        expect(measurer.find_component(command)).to eq('c1')
      end
    end

    context 'command match no pattern' do
      let(:command) { 'p4' }

      it 'return nil' do
        allow(measurer).to receive(:component_command_patterns).and_return(component_command_patterns)
        expect(measurer.find_component(command)).to be_nil
      end
    end

    context 'command match two patterns' do
      let(:command) { 'p1 p2' }

      it 'raise error' do
        allow(measurer).to receive(:component_command_patterns).and_return(component_command_patterns)
        expect { measurer.find_component(command) }.to raise_error(SystemExit, /matches more than one components/)
      end
    end
  end

  describe '.add_full_command_and_component_to_smem_result_hash' do
    let(:debug_output_dir) { nil }
    let(:component_command_patterns) { { 'c1' => /^runsv sshd/, 'c2' => /^\/bin\/bash \/assets\/wrapper/, 'c3' => /p3/ } }
    let(:pid_command_hash_array) do
      [
        { 'PID' => '1', 'COMMAND' => '/bin/bash /assets/wrapper' },
        { 'PID' => '23', 'COMMAND' => 'runsv sshd' },
        { 'PID' => '24', 'COMMAND' => 'svlogd -tt /var/log/gitlab/sshd' }
      ]
    end
    let(:smem_result_hash_array) do
      [
        { 'PID' => '23', 'User' => 'git', 'Command' => 'runsv', 'Swap' => '3504', 'USS' => '432', 'PSS' => '443', 'RSS' => '1452' },
        { 'PID' => '1', 'User' => 'git', 'Command' => '/bin/bash', 'Swap' => '148', 'USS' => '240', 'PSS' => '523', 'RSS' => '2476' }
      ]
    end
    let(:expected_ret) do
      [
        { 'PID' => '23', 'User' => 'git', 'Command' => 'runsv', 'Swap' => '3504', 'USS' => '432', 'PSS' => '443', 'RSS' => '1452', 'COMMAND' => 'runsv sshd', 'COMPONENT' => 'c1' },
        { 'PID' => '1', 'User' => 'git', 'Command' => '/bin/bash', 'Swap' => '148', 'USS' => '240', 'PSS' => '523', 'RSS' => '2476', 'COMMAND' => '/bin/bash /assets/wrapper', 'COMPONENT' => 'c2' }
      ]
    end

    it 'should return updated hash with command and component' do
      allow(measurer).to receive(:component_command_patterns).and_return(component_command_patterns)
      expect(measurer.add_full_command_and_component_to_smem_result_hash(pid_command_hash_array, smem_result_hash_array)).to eq(expected_ret)
    end
  end

  describe '.sum_memory_by_component' do
    let(:debug_output_dir) { nil }

    context 'given smem hash array' do
      let(:smem_result_hash_array) do
        [
          { 'PID' => '23', 'User' => 'User23', 'Command' => 'runsv23', 'Swap' => '3504', 'USS' => '100', 'PSS' => '1000', 'RSS' => '10000', 'COMMAND' => 'COMMAND23', 'COMPONENT' => 'c1' },
          { 'PID' => '24', 'User' => 'User24', 'Command' => 'runsv24', 'Swap' => '3504', 'USS' => '200', 'PSS' => '2000', 'RSS' => '20000', 'COMMAND' => 'COMMAND24', 'COMPONENT' => nil },
          { 'PID' => '27', 'User' => 'User27', 'Command' => 'runsv27', 'Swap' => '3504', 'USS' => '20', 'PSS' => '200', 'RSS' => '2000', 'COMMAND' => 'COMMAND27', 'COMPONENT' => nil },
          { 'PID' => '25', 'User' => 'User25', 'Command' => 'runsv25', 'Swap' => '3505', 'USS' => '400', 'PSS' => '4000', 'RSS' => '40000', 'COMMAND' => 'COMMAND25', 'COMPONENT' => 'c1' },
          { 'PID' => '26', 'User' => 'User26', 'Command' => 'runsv26', 'Swap' => '3504', 'USS' => '800', 'PSS' => '8000', 'RSS' => '80000', 'COMMAND' => 'COMMAND26', 'COMPONENT' => 'c2' },
        ]
      end
      let(:expected_ret) do
        {
          'c1' => { 'USS' => 500.0, 'PSS' => 5000.0, 'RSS' => 50000.0 },
          nil => { 'USS' => 220.0, 'PSS' => 2200.0, 'RSS' => 22000.0 },
          'c2' => { 'USS' => 800.0, 'PSS' => 8000.0, 'RSS' => 80000.0 }
        }
      end

      it 'return component memory usage hash' do
        expect(measurer.sum_memory_by_component(smem_result_hash_array)).to eq(expected_ret)
      end
    end
  end

  describe '.smem_sum_hash_as_metrics' do
    let(:debug_output_dir) { nil }

    context 'given smem summarised hash with some nil component' do
      let(:smem_sum_hash) do
        {
          'c1' => { 'USS' => 500.0, 'PSS' => 5000.0, 'RSS' => 50000.0 },
          nil => { 'USS' => 220.0, 'PSS' => 2200.0, 'RSS' => 22000.0 },
          'c2' => { 'USS' => 800.0, 'PSS' => 8000.0, 'RSS' => 80000.0 }
        }
      end
      let(:expected_ret) do
        [
          "uss_size_kb{component=\"c1\"} 500.0",
          "pss_size_kb{component=\"c1\"} 5000.0",
          "rss_size_kb{component=\"c1\"} 50000.0",
          "uss_size_kb{component=\"c2\"} 800.0",
          "pss_size_kb{component=\"c2\"} 8000.0",
          "rss_size_kb{component=\"c2\"} 80000.0"
        ]
      end

      it 'return metrics ignore nil component' do
        expect(measurer.smem_sum_hash_as_metrics(smem_sum_hash)).to eq(expected_ret)
      end
    end
  end
end
