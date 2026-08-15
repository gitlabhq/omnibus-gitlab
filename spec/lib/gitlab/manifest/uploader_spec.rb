require 'spec_helper'
require 'gitlab/manifest/uploader'

RSpec.describe Manifest::Uploader do
  # Bypass the heavy initialize (which shells out via Build::Info) and set only
  # the ivars the methods under test rely on.
  subject(:uploader) { described_class.allocate }

  let(:generator) { instance_double(Manifest::Generator, manifest_filename: 'version-manifest.json') }
  let(:local_path) { Dir.mktmpdir }
  let(:target_path) { File.join(local_path, 'gitlab-ee', '19.0', '19.0.5-ee.version-manifest.json') }

  before do
    uploader.instance_variable_set(:@generator, generator)
    uploader.instance_variable_set(:@edition, 'ee')
    uploader.instance_variable_set(:@package, 'gitlab-ee')
    uploader.instance_variable_set(:@current_version, '19.0.5')
    uploader.instance_variable_set(:@current_minor_version, '19.0')
    uploader.instance_variable_set(:@manifests_bucket_path, 'my-bucket/gitlab-manifests')
    uploader.instance_variable_set(:@manifests_local_path, local_path)
  end

  after { FileUtils.remove_entry(local_path) }

  describe '#target_manifest_path' do
    it 'builds <package>/<minor>/<version>-<edition>.<filename>' do
      expect(uploader.target_manifest_path).to eq(target_path)
    end
  end

  describe '#overwrite?' do
    it 'defaults to true when MANIFEST_OVERWRITE is unset' do
      allow(Gitlab::Util).to receive(:get_env).with('MANIFEST_OVERWRITE').and_return(nil)

      expect(uploader.overwrite?).to be(true)
    end

    it 'is false only when MANIFEST_OVERWRITE is exactly "false"' do
      allow(Gitlab::Util).to receive(:get_env).with('MANIFEST_OVERWRITE').and_return('false')

      expect(uploader.overwrite?).to be(false)
    end

    it 'is true when MANIFEST_OVERWRITE is "true"' do
      allow(Gitlab::Util).to receive(:get_env).with('MANIFEST_OVERWRITE').and_return('true')

      expect(uploader.overwrite?).to be(true)
    end
  end

  describe '#verify_no_overwrite!' do
    it 'does nothing when the target manifest does not exist' do
      expect { uploader.verify_no_overwrite! }.not_to raise_error
    end

    it 'raises when the target manifest already exists' do
      FileUtils.mkdir_p(File.dirname(target_path))
      FileUtils.touch(target_path)

      expect { uploader.verify_no_overwrite! }
        .to raise_error(RuntimeError, /already exists.*MANIFEST_OVERWRITE=true/m)
    end
  end

  describe '#execute' do
    before { allow(generator).to receive(:create_manifest) }

    it 'raises when the S3 fetch fails and overwrite protection is enabled' do
      allow(uploader).to receive_messages(s3_fetch: false, overwrite?: false)

      expect { uploader.execute }.to raise_error(RuntimeError, /S3 fetch .* failed/)
    end

    it 'does not run the overwrite check when overwriting is allowed' do
      allow(uploader).to receive_messages(s3_fetch: false, overwrite?: true,
                                          copy_manifests: nil, s3_upload: nil)

      expect(uploader).not_to receive(:verify_no_overwrite!)
      expect { uploader.execute }.not_to raise_error
    end
  end
end
