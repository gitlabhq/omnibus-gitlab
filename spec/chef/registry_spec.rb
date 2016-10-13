require 'chef_helper'

describe 'registry' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before { allow(Gitlab).to receive(:[]).and_call_original }

  context 'when registry is enabled' do
    before { stub_gitlab_rb(registry_external_url: 'https://registry.example.com') }

    it 'sets default storage options' do
      expect(chef_run.node['gitlab']['registry']['storage']['filesystem'])
        .to eql('rootdirectory' => '/var/opt/gitlab/gitlab-rails/shared/registry')
      expect(chef_run.node['gitlab']['registry']['storage']['cache'])
        .to eql('blobdescriptor'=>'inmemory')
      expect(chef_run.node['gitlab']['registry']['storage']['delete'])
        .to eql('enabled' => true)
    end

    context 'when custom storage parameters are specified' do
      before do
        stub_gitlab_rb(
          registry: {
            storage: {
              s3: { accesskey: 'awsaccesskey', secretkey: 'awssecretkey', bucketname: 'bucketname' }
            }
          }
        )
      end

      it 'uses custom storage instead of the default rootdirectory' do
        expect(chef_run.node['gitlab']['registry']['storage'])
          .to include(s3: { accesskey: 'awsaccesskey', secretkey: 'awssecretkey', bucketname: 'bucketname' })
        expect(chef_run.node['gitlab']['registry']['storage'])
          .not_to include('rootdirectory' => '/var/opt/gitlab/gitlab-rails/shared/registry')
      end

      it 'uses the default cache and delete settings if not overridden' do
        expect(chef_run.node['gitlab']['registry']['storage']['cache'])
          .to eql('blobdescriptor'=>'inmemory')
        expect(chef_run.node['gitlab']['registry']['storage']['delete'])
          .to eql('enabled' => true)
      end

      it 'allows the cache and delete settings to be overridden' do
        stub_gitlab_rb(registry: { storage: {cache: 'somewhere-else', delete: { enabled: false } } })
        expect(chef_run.node['gitlab']['registry']['storage']['cache'])
          .to eql('somewhere-else')
        expect(chef_run.node['gitlab']['registry']['storage']['delete'])
          .to eql('enabled' => false)
      end
    end

    context 'when storage_delete_enabled is false' do
      before { stub_gitlab_rb(registry: { storage_delete_enabled: false }) }

      it 'sets the delete enabled field on the storage object' do
        expect(chef_run.node['gitlab']['registry']['storage']['delete'])
          .to eql('enabled' => false)
      end
    end
  end
end
