require 'spec_helper'
require 'gitlab/docker_helper'

RSpec.describe DockerHelper do
  describe '.authenticate' do
    before do
      stdin_mock = double(puts: true, close: true)
      stdout_mock = double(read: true)
      stderr_mock = double(read: true)
      wait_thr_mock = double(value: double(success?: true))

      allow(Open3).to receive(:popen3).with({}, "docker", "login", any_args).and_yield(stdin_mock, stdout_mock, stderr_mock, wait_thr_mock)
    end

    context 'when a registry is not specified' do
      it 'runs the command to login to docker.io' do
        expect(Open3).to receive(:popen3).with({}, "docker", "login", "--username=dummy-username", "--password-stdin", "")

        described_class.authenticate(username: 'dummy-username', password: 'dummy-password')
      end
    end

    context 'when a registry is specified' do
      it 'runs the command to login to specified registry' do
        expect(Open3).to receive(:popen3).with({}, "docker", "login", "--username=dummy-username", "--password-stdin", "registry.gitlab.com")

        described_class.authenticate(username: 'dummy-username', password: 'dummy-password', registry: 'registry.gitlab.com')
      end
    end
  end

  describe '.build' do
    shared_examples 'docker build command invocation' do
    end

    before do
      stdout_stderr_mock = double(gets: nil)
      status_mock = double(value: double(success?: true))

      allow(described_class).to receive(:create_builder).and_return(true)

      allow(Open3).to receive(:popen2e).with("docker", "buildx", "build", any_args).and_yield(nil, stdout_stderr_mock, status_mock)
    end

    context 'when a single platform is specified' do
      context 'when push is not explicitly disabled' do
        let(:expected_args) { %w[docker buildx build /tmp/foo -t sample:value --platform=linux/amd64 --push] }

        it 'calls docker build command with correct arguments' do
          expect(Open3).to receive(:popen2e).with(*expected_args)

          described_class.build('/tmp/foo', 'sample', 'value')
        end
      end

      context 'when push is explicitly disabled' do
        let(:expected_args) { %w[docker buildx build /tmp/foo -t sample:value --platform=linux/amd64] }

        it 'calls docker build command with correct arguments' do
          expect(Open3).to receive(:popen2e).with(*expected_args)

          described_class.build('/tmp/foo', 'sample', 'value', push: false)
        end
      end
    end

    context 'when multiple platforms are specified via env vars' do
      before do
        stub_env_var('DOCKER_BUILD_PLATFORMS', 'linux/arm64')
      end

      let(:expected_args) { %w[docker buildx build /tmp/foo -t sample:value --platform=linux/amd64,linux/arm64 --push] }

      it 'calls docker build command with correct arguments' do
        expect(Open3).to receive(:popen2e).with(*expected_args)

        described_class.build('/tmp/foo', 'sample', 'value')
      end

      context 'even if push is explicitly disabled' do
        let(:expected_args) { %w[docker buildx build /tmp/foo -t sample:value --platform=linux/amd64,linux/arm64 --push] }

        it 'calls docker build command with correct arguments' do
          expect(Open3).to receive(:popen2e).with(*expected_args)

          described_class.build('/tmp/foo', 'sample', 'value', push: false)
        end
      end
    end

    context 'when build_args are specified' do
      let(:expected_args) { %w[docker buildx build /tmp/foo -t sample:value --platform=linux/amd64 --push --build-arg='FOO=BAR'] }

      it 'calls docker build command with correct arguments' do
        expect(Open3).to receive(:popen2e).with(*expected_args)

        described_class.build('/tmp/foo', 'sample', 'value', buildargs: ["FOO=BAR"])
      end
    end
  end

  describe '.create_builder' do
    before do
      allow(described_class).to receive(:cleanup_existing_builder).and_return(true)

      stdout_stderr_mock = double(gets: nil)
      status_mock = double(value: double(success?: true))
      allow(Open3).to receive(:popen2e).with("docker", "buildx", "create", any_args).and_return([nil, stdout_stderr_mock, status_mock])
    end

    it 'calls docker buildx create command with correct arguments' do
      expect(Open3).to receive(:popen2e).with(*%w[docker buildx create --bootstrap --use --name omnibus-gitlab-builder])

      described_class.create_builder
    end
  end

  describe '.cleanup_existing_builder' do
    context 'when no builder instance exist' do
      before do
        status_mock = double(value: double(success?: false))
        allow(Open3).to receive(:popen2e).with("docker", "buildx", "ls", any_args).and_return([nil, nil, status_mock])
      end

      it 'does not call docker buildx rm' do
        expect(Open3).not_to receive(:popen2e).with(*%w[docker buildx rm --force omnibus-gitlab-builder])

        described_class.cleanup_existing_builder
      end
    end

    context 'when builder instance exists' do
      before do
        status_mock = double(value: double(success?: true))
        allow(Open3).to receive(:popen2e).with("docker", "buildx", "ls", any_args).and_return([nil, nil, status_mock])
        allow(Open3).to receive(:popen2e).with("docker", "buildx", "rm", any_args).and_return([nil, nil, status_mock])
      end

      it 'calls docker buildx rm command with correct arguments' do
        expect(Open3).to receive(:popen2e).with(*%w[docker buildx rm --force omnibus-gitlab-builder])

        described_class.cleanup_existing_builder
      end
    end
  end
end
