require 'spec_helper'
require 'gitlab/skopeo_helper'

RSpec.describe SkopeoHelper do
  before do
    allow(described_class).to receive(:system).and_return(true)
  end

  describe '.login' do
    it 'calls skopeo login command with correct arguments' do
      stdin_mock = double(puts: true, close: true)
      wait_thr_mock = double(value: double(success?: true))
      allow(Open3).to receive(:popen3).with({}, "skopeo", "login", any_args).and_yield(stdin_mock, nil, nil, wait_thr_mock)

      expect(Open3).to receive(:popen3).with({}, *%w[skopeo login --tls-verify --username=foo --password-stdin registry.example.com])
      expect(stdin_mock).to receive(:puts).with("bar")

      described_class.login('foo', 'bar', 'registry.example.com')
    end
  end

  describe '.copy_image' do
    it 'waits for source image to be available and raises error if image is not found' do
      stdout_stderr_mock = double(read: 'dummy_output')
      wait_thr_mock = double(value: double(success?: false))
      allow(Open3).to receive(:popen2e).with(*%w[skopeo inspect docker://foobar]).and_yield(nil, stdout_stderr_mock, wait_thr_mock)

      expect(Open3).to receive(:popen2e).with(*%w[skopeo inspect docker://foobar]).exactly(30).times

      expect { described_class.copy_image('foobar', 'dummy-target') }.to raise_error(SkopeoHelper::ImageNotFoundError).with_message("Image `foobar` not found.")
    end

    it 'calls skopeo copy command with correct arguments' do
      allow(Open3).to receive(:popen2e).with(*%w[skopeo inspect docker://foobar]).and_yield(nil, double(read: 'dummy_output'), double(value: double(success?: true)))

      expect(described_class).to receive(:system).with(*%w[skopeo copy docker://foobar docker://dummy-target])

      described_class.copy_image('foobar', 'dummy-target')
    end
  end
end
