require_relative '../../../lib/gitlab/build/image.rb'
require 'chef_helper'

describe Build::Image do
  describe 'write_release_file' do
    describe 'with triggered build' do
      let(:release_file) do
        [
          "PACKAGECLOUD_REPO=download-package",
          "RELEASE_VERSION=12.121.12-ce.1",
          "DOWNLOAD_URL=https://gitlab.example.com/project/repository/builds/1/artifacts/raw/pkg/ubuntu-xenial/gitlab.deb",
          "TRIGGER_PRIVATE_TOKEN=NOT-PRIVATE-TOKEN\n"
        ]
      end

      before do
        stub_env_var('PACKAGECLOUD_REPO', 'download-package')
        stub_env_var('TRIGGER_PRIVATE_TOKEN', 'NOT-PRIVATE-TOKEN')
        stub_env_var('CI_PROJECT_URL', 'https://gitlab.example.com/project/repository')
        stub_env_var('CI_PROJECT_ID', '1')
        stub_env_var('CI_PIPELINE_ID', '2')
        allow(Build::Info).to receive(:release_version).and_return('12.121.12-ce.1')
        allow(described_class).to receive(:fetch_artifact_url).with('1', '2').and_return('1')
      end

      describe 'for CE' do
        before do
          allow(Build::Info).to receive(:package).and_return('gitlab-ce')
        end

        it 'returns build version and iteration with env variable' do
          release_file_content = release_file.insert(1, 'RELEASE_PACKAGE=gitlab-ce').join("\n")
          expect(described_class.write_release_file).to eq(release_file_content)
        end
      end

      describe 'for EE' do
        before do
          allow(Build::Info).to receive(:package).and_return('gitlab-ee')
        end

        it 'returns build version and iteration with env variable' do
          release_file_content = release_file.insert(1, 'RELEASE_PACKAGE=gitlab-ee').join("\n")
          expect(described_class.write_release_file).to eq(release_file_content)
        end
      end

      describe 'with regular build' do
        let(:s3_download_link) { 'https://downloads-packages.s3.amazonaws.com/ubuntu-xenial/gitlab-ee_12.121.12-ce.1_amd64.deb' }

        let(:release_file) do
          [
            "RELEASE_VERSION=12.121.12-ce.1",
            "DOWNLOAD_URL=#{s3_download_link}\n",
          ]
        end

        before do
          stub_env_var('PACKAGECLOUD_REPO', '')
          stub_env_var('TRIGGER_PRIVATE_TOKEN', '')
          stub_env_var('CI_PROJECT_ID', '')
          stub_env_var('CI_PIPELINE_ID', '')
          allow(Build::Check).to receive(:on_tag?).and_return(true)
          allow(Build::Info).to receive(:package).and_return('gitlab-ee')
          allow(described_class).to receive(:release_version).and_return('12.121.12-ce.1')
        end

        it 'returns build version and iteration with env variable' do
          release_file_content = release_file.insert(0, 'RELEASE_PACKAGE=gitlab-ee').join("\n")
          expect(described_class.write_release_file).to eq(release_file_content)
        end
      end
    end
  end
end
