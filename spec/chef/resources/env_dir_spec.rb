require 'chef_helper'

describe 'env_dir' do
  context 'env enabled' do
    let(:service) { 'gitaly' }
    let(:service_env_dir) { Dir.mktmpdir }
    let(:runner) do
      ChefSpec::SoloRunner.new(step_into: %w(env_dir)) do |node|
        node.normal['gitaly']['env_directory'] = service_env_dir
        node.normal['gitaly']['env'] = { 'http_proxy' => 'test' }
      end
    end
    let(:chef_run) { runner.converge("gitlab::default") }

    before do
      FileUtils.mkdir_p(service_env_dir)
    end

    after do
      FileUtils.rm_rf(service_env_dir)
    end

    it 'creates env variable' do
      expect(chef_run).to create_file("#{service_env_dir}/http_proxy").with_content('test')
    end

    it 'deletes extraneous files' do
      FileUtils.touch(File.join(service_env_dir, 'erase-me'))

      expect(chef_run).to delete_file("#{service_env_dir}/erase-me")
    end
  end
end
