require 'spec_helper'
require 'gitlab/docker_operations'

describe DockerOperations do
  describe '.set_timeout' do
    context 'when ENV["DOCKER_TIMEOUT"] is not set' do
      it 'uses a default timeout value' do
        expect(Docker).to receive(:options=).with(read_timeout: 1200, write_timeout: 1200)

        described_class.set_timeout
      end
    end

    context 'when ENV["DOCKER_TIMEOUT"] is not set' do
      before do
        expect(ENV).to receive(:[]).with('DOCKER_TIMEOUT').and_return("42")
      end

      it 'uses the given timeout value' do
        expect(Docker).to receive(:options=).with(read_timeout: "42", write_timeout: "42")

        described_class.set_timeout
      end
    end
  end

  describe '.build' do
    let(:location) { '/tmp/foo' }
    let(:image) { 'gitlab-ce' }
    let(:tag) { 'latest' }

    it 'uses a default timeout value' do
      expect(described_class).to receive(:set_timeout)
      expect(Docker::Image).to receive(:build_from_dir).with(location, { t: "#{image}:#{tag}", pull: true }).and_yield(JSON.dump(stream: 'Hello!'))
      expect(described_class).to receive(:puts).with('Hello!')

      described_class.build(location.to_sym, image, tag)
    end
  end

  describe '.authenticate' do
    context 'with no arguments' do
      it 'calls Docker.authenticate!' do
        expect(ENV).to receive(:[]).with('DOCKERHUB_USERNAME').and_return('user')
        expect(ENV).to receive(:[]).with('DOCKERHUB_PASSWORD').and_return('pass')
        expect(Docker).to receive(:authenticate!).with(username: 'user', password: 'pass', serveraddress: '')

        described_class.authenticate
      end
    end

    context 'with arguments' do
      it 'uses a default timeout value' do
        expect(Docker).to receive(:authenticate!).with(username: 'john', password: 'secret', serveraddress: 'registry.com')

        described_class.authenticate('john', 'secret', 'registry.com')
      end
    end
  end

  describe '.get' do
    it 'calls Docker::Image.get' do
      expect(described_class).to receive(:set_timeout)
      expect(Docker::Image).to receive(:get).with('namespace:tag')

      described_class.get('namespace', 'tag')
    end
  end

  describe '.push' do
    it 'calls Docker::Image.push' do
      image = double
      creds = double

      expect(described_class).to receive(:set_timeout)
      expect(described_class).to receive(:get).with('namespace', 'tag').and_return(image)
      expect(Docker).to receive(:creds).and_return(creds)
      expect(image).to receive(:push).with(creds, repo_tag: 'namespace:tag').and_yield('Hello!')
      expect(described_class).to receive(:puts).and_return('Hello!')

      described_class.push('namespace', 'tag')
    end
  end

  describe '.tag' do
    it 'calls Docker::Image.tag' do
      image = double

      expect(described_class).to receive(:set_timeout)
      expect(described_class).to receive(:get).with('namespace1', 'tag1').and_return(image)
      expect(image).to receive(:tag).with(repo: 'namespace2', tag: 'tag2', force: true)

      described_class.tag('namespace1', 'namespace2', 'tag1', 'tag2')
    end
  end

  describe '.tag_and_push' do
    it 'delegates to tag_and_push' do
      expect(described_class).to receive(:tag).with('namespace1', 'namespace2', 'tag1', 'tag2')
      expect(described_class).to receive(:push).with('namespace2', 'tag2')

      described_class.tag_and_push('namespace1', 'namespace2', 'tag1', 'tag2')
    end
  end
end
