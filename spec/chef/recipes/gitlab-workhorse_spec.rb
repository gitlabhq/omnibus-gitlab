require 'chef_helper'

describe 'gitlab::gitlab-workhorse' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original

    # Prevent chef converge from reloading the helper library, which would override our helper stub
    allow(Kernel).to receive(:load).and_call_original
    allow(Kernel).to receive(:load).with(%r{gitlab/libraries/storage_directory_helper}).and_return(true)
  end

  context 'with environment variables' do
    context 'by default' do
      it_behaves_like "enabled gitlab-workhorse env", "HOME", '\/var\/opt\/gitlab'
      it_behaves_like "enabled gitlab-workhorse env", "PATH", '\/opt\/gitlab\/bin:\/opt\/gitlab\/embedded\/bin:\/bin:\/usr\/bin'

      context 'when a custom env variable is specified' do
        before do
          stub_gitlab_rb(gitlab_workhorse: { env: { 'IAM' => 'CUSTOMVAR'}})
        end

        it_behaves_like "enabled gitlab-workhorse env", "IAM", 'CUSTOMVAR'
      end
    end
  end
end
