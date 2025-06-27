require 'chef_helper'

RSpec.describe 'gitlab-base::default' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge('gitlab-base::default') }

  before do
    # We can't use `include_recipe` matcher because then it will attempt to
    # execute the recipe being included. Hence, we will stub the
    # `include_recipe` method, and test if that method was called.
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_call_original
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('gitlab-jh::default')
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('gitlab-ee::default')
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('gitlab::default')
  end

  context 'when the gitlab-jh cookbook exists' do
    before do
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with(/gitlab-jh$/).and_return(true)
      allow(Dir).to receive(:exist?).with(/gitlab-ee$/).and_return(false)
      allow(Dir).to receive(:exist?).with(/gitlab$/).and_return(false)
    end

    it 'includes the gitlab-jh::default recipe' do
      expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('gitlab-jh::default')

      chef_run
    end
  end

  context 'when the gitlab-ee cookbook exists' do
    before do
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with(/gitlab-jh$/).and_return(false)
      allow(Dir).to receive(:exist?).with(/gitlab-ee$/).and_return(true)
      allow(Dir).to receive(:exist?).with(/gitlab$/).and_return(false)
    end

    it 'includes the gitlab-ee::default recipe' do
      expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('gitlab-ee::default')

      chef_run
    end
  end

  context 'when the gitlab cookbook exists' do
    before do
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with(/gitlab-jh$/).and_return(false)
      allow(Dir).to receive(:exist?).with(/gitlab-ee$/).and_return(false)
      allow(Dir).to receive(:exist?).with(/gitlab$/).and_return(true)
    end

    it 'includes the gitlab::default recipe' do
      expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('gitlab::default')

      chef_run
    end
  end

  context 'when no gitlab cookbooks exist' do
    before do
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with(/gitlab-ee$/).and_return(false)
      allow(Dir).to receive(:exist?).with(/gitlab-jh$/).and_return(false)
      allow(Dir).to receive(:exist?).with(/gitlab$/).and_return(false)
    end

    it 'does not include any gitlab recipe' do
      expect(chef_run).not_to include_recipe('gitlab-jh::default')
      expect(chef_run).not_to include_recipe('gitlab-ee::default')
      expect(chef_run).not_to include_recipe('gitlab::default')
    end
  end
end
