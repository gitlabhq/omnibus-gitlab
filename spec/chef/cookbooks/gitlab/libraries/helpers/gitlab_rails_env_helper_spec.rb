require 'chef_helper'

RSpec.describe GitlabRailsEnvHelper do
  describe '.bundle_gemfile' do
    let(:source_dir) { Dir.mktmpdir }

    after do
      FileUtils.rm_rf(source_dir)
    end

    def write_bundle_config(content)
      FileUtils.mkdir_p(File.join(source_dir, '.bundle'))
      File.write(File.join(source_dir, '.bundle', 'config'), content)
    end

    it 'returns the default Gemfile when there is no bundle config' do
      expect(described_class.bundle_gemfile(source_dir)).to eq("#{source_dir}/Gemfile")
    end

    it 'returns the default Gemfile when the bundle config does not set a Gemfile' do
      write_bundle_config(%(---\nBUNDLE_FROZEN: "true"\n))

      expect(described_class.bundle_gemfile(source_dir)).to eq("#{source_dir}/Gemfile")
    end

    it 'expands a relative Gemfile against the source directory' do
      write_bundle_config(%(---\nBUNDLE_GEMFILE: "Gemfile.next"\n))

      expect(described_class.bundle_gemfile(source_dir)).to eq("#{source_dir}/Gemfile.next")
    end

    it 'keeps an absolute Gemfile unchanged' do
      write_bundle_config(%(---\nBUNDLE_GEMFILE: "/opt/gitlab/embedded/service/gitlab-rails/Gemfile.next"\n))

      expect(described_class.bundle_gemfile(source_dir)).to eq('/opt/gitlab/embedded/service/gitlab-rails/Gemfile.next')
    end
  end
end
