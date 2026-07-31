require 'spec_helper'
require 'omnibus-ctl'
require 'gitlab_ctl'

RSpec.describe 'gitlab-ctl check-config' do
  subject(:ctl) { Omnibus::Ctl.new('testing-ctl') }

  let(:output) { StringIO.new }
  let(:node_file) { '/opt/testing-ctl/embedded/nodes/fake.json' }

  before do
    ctl.fh_output = output
    # Omnibus::Ctl#load_file uses a bare `eval`, which breaks the
    # `require_relative` calls in check_config.rb. Evaluate the file with its
    # path so those relative requires resolve, matching runtime behavior.
    ctl_file = File.expand_path('files/gitlab-ctl-commands/check_config.rb')
    ctl.instance_eval(File.read(ctl_file), ctl_file)

    allow(Dir).to receive(:glob).and_call_original
    allow(Dir).to receive(:glob).with('/opt/testing-ctl/embedded/nodes/*.json').and_return([node_file])
    allow(GitlabCtl::Util).to receive(:public_attributes_broken?).and_return(false)
    stub_const('ARGV', ['--version=17.0'])
  end

  it 'appends a check-config command' do
    expect(ctl.get_all_commands_hash).to include('check-config')
  end

  context 'when no node attributes file exists' do
    before do
      allow(Dir).to receive(:glob).with('/opt/testing-ctl/embedded/nodes/*.json').and_return([])
    end

    it 'skips the check and exits successfully' do
      expect { ctl.check_config('check-config') }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(0)
      end
      expect(output.string).to include('Skipping config check')
    end
  end

  context 'when the public attributes file is broken' do
    before do
      allow(GitlabCtl::Util).to receive(:public_attributes_broken?).and_return(true)
    end

    it 'exits with a failure code' do
      expect { ctl.check_config('check-config') }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
      expect(output.string).to include('Public attributes file is missing')
    end
  end

  context 'when the node attributes file is malformed' do
    before do
      # A failed or interrupted reconfigure leaves a node file without the
      # "normal" key. See https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/9455
      allow(JSON).to receive(:load_file).with(node_file).and_return('default' => {})
    end

    it 'skips the check and exits successfully instead of blocking the upgrade' do
      expect { ctl.check_config('check-config') }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(0)
      end
    end

    it 'explains that the file will be regenerated on the next reconfigure' do
      expect { ctl.check_config('check-config') }.to raise_error(SystemExit)
      expect(output.string).to include('Malformed configuration JSON file found')
      expect(output.string).to include('regenerated on the next reconfigure')
    end
  end

  context 'when the node attributes file is valid' do
    before do
      allow(JSON).to receive(:load_file).with(node_file).and_return('normal' => { 'gitlab' => {} })
    end

    context 'and there are no deprecated configurations' do
      before do
        allow(Gitlab::Deprecations).to receive(:check_config).and_return([])
      end

      it 'exits successfully' do
        expect { ctl.check_config('check-config') }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
      end
    end

    context 'and there are deprecated configurations' do
      before do
        allow(Gitlab::Deprecations).to receive(:check_config).and_return(['gitlab_rails["foo"] has been removed'])
      end

      it 'reports the deprecations and exits with a failure code' do
        expect { ctl.check_config('check-config') }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
        expect(output.string).to include('Deprecations found')
      end

      context 'with --no-fail' do
        before do
          stub_const('ARGV', ['--version=17.0', '--no-fail'])
        end

        it 'reports the deprecations but exits successfully' do
          expect { ctl.check_config('check-config') }.to raise_error(SystemExit) do |error|
            expect(error.status).to eq(0)
          end
          expect(output.string).to include('Deprecations found')
        end
      end
    end
  end
end
