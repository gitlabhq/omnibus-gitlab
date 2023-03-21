require 'spec_helper'
require 'gitlab/gcloud_helper'

RSpec.describe GCloudHelper do
  let(:status_failed) { double("status", success?: false, exitstatus: 1) }
  let(:status_success) { double("status", success?: true, exitstatus: 0) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('GITLAB_COM_PKGS_SA_FILE').and_return('/path/to/sa')
    allow(Build::Check).to receive(:on_tag?).and_return(false)
  end

  describe '.gcs_sync!' do
    it 'exits with error when activation fails' do
      expect(Open3).to receive(:capture2e).once.and_return(['sa activation', status_failed])

      expect(described_class.gcs_sync!('some-dir/')).to eq('Service account activation failed! ret=1 out=sa activation')
    end

    context 'with successful activation' do
      before do
        allow(Open3).to receive(:capture2e).with('gcloud auth activate-service-account --key-file /path/to/sa').and_return(['sa activation', status_success])
      end

      it 'raises an error if rsync fails after retries' do
        expect(Open3).to receive(:capture2e).with('gsutil -o GSUtil:parallel_composite_upload_threshold=150M -m rsync -r some-dir/ gs://gitlab-com-pkgs-builds').exactly(4).times.and_return(['gcs rsync output', status_failed])

        expect { described_class.gcs_sync!('some-dir/') }.to raise_error(GCloudHelper::GCSSyncError)
      end

      it 'rsyncs packages to the package bucket' do
        allow(Open3).to receive(:capture2e).with('gsutil -o GSUtil:parallel_composite_upload_threshold=150M -m rsync -r some-dir/ gs://gitlab-com-pkgs-builds').and_return(['gcs rsync output', status_success])

        expect(described_class.gcs_sync!('some-dir/')).to eq('gcs rsync output')
      end
    end
  end

  describe '.signed_urls' do
    it 'exits with error when activation fails' do
      expect(Open3).to receive(:capture2e).once.and_return(['sa activation', status_failed])

      expect(described_class.signed_urls(%w[pkg/1 pkg/2 pkg/3])).to eq('Service account activation failed! ret=1 out=sa activation')
    end

    context 'with successful activation' do
      before do
        allow(Open3).to receive(:capture2e).with('gcloud auth activate-service-account --key-file /path/to/sa').and_return(['sa activation', status_success])
      end

      it 'exits with error when signed URLs fail to generate' do
        allow(Open3).to receive(:capture2e).with('gsutil signurl -r us-east1 --use-service-account -d 12h gs://gitlab-com-pkgs-builds/pkg/1 gs://gitlab-com-pkgs-builds/pkg/2 gs://gitlab-com-pkgs-builds/pkg/3').once.and_return(['signurl output', status_failed])

        expect(described_class.signed_urls(%w[pkg/1 pkg/2 pkg/3])).to eq('Unable to generate signed URL for gs://gitlab-com-pkgs-builds/pkg/1 gs://gitlab-com-pkgs-builds/pkg/2 gs://gitlab-com-pkgs-builds/pkg/3! ret=1 out=signurl output')
      end

      it 'generates signed urls' do
        allow(Open3).to receive(:capture2e).with('gsutil signurl -r us-east1 --use-service-account -d 12h gs://gitlab-com-pkgs-builds/pkg/1 gs://gitlab-com-pkgs-builds/pkg/2 gs://gitlab-com-pkgs-builds/pkg/3').once.and_return(['signurl output', status_success])

        expect(described_class.signed_urls(%w[pkg/1 pkg/2 pkg/3])).to eq('signurl output')
      end
    end
  end
end
