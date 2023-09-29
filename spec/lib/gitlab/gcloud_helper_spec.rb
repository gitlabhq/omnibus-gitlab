require 'spec_helper'
require 'gitlab/gcloud_helper'

class StubGoogleCloudBucket
  def upload_file(source, destination); end

  def signed_url(path, version: :v4)
    "signed-#{path}"
  end
end

RSpec.describe GCloudHelper do
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(Build::Check).to receive(:on_tag?).and_return(false)
    allow(Google::Cloud::Storage).to receive(:new).and_return(double(bucket: StubGoogleCloudBucket.new))
  end

  describe '.upload_packages_and_print_urls' do
    context 'when SA file variable not defined' do
      before do
        stub_env_var('GITLAB_COM_PKGS_SA_FILE', '')
      end

      it 'prints error message' do
        expect(described_class).to receive(:warn).with(/Error finding service account file./)

        described_class.upload_packages_and_print_urls('pkg/')
      end
    end

    context 'when file mentioned in SA variable does not exist' do
      before do
        stub_env_var('GITLAB_COM_PKGS_SA_FILE', 'a-dummy-file')
        allow(::File).to receive(:exist?).with('a-dummy-file').and_return(false)
      end

      it 'prints error message' do
        expect(described_class).to receive(:warn).with(/Error finding service account file./)

        described_class.upload_packages_and_print_urls('pkg/')
      end
    end

    context 'when service account file exists' do
      before do
        stub_env_var('GITLAB_COM_PKGS_SA_FILE', 'a-dummy-file')
        allow(::File).to receive(:exist?).with('a-dummy-file').and_return(true)
        allow(::Dir).to receive(:glob).with(/pkg/).and_return(%w[one two three])
      end

      it 'prints signed URLs' do
        expect { described_class.upload_packages_and_print_urls('pkg/') }.to output(/signed-one\nsigned-two\nsigned-three/).to_stdout
      end
    end
  end
end
