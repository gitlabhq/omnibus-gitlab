require 'chef_helper'

RSpec.describe 'registry::enable' do
  let(:chef_runner) do
    ChefSpec::SoloRunner.new(step_into: %w(registry_enable))
  end

  let(:chef_run) do
    chef_runner.converge('gitlab-ee::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(registry_external_url: 'https://registry.example.com')
    allow_any_instance_of(RegistryPgHelper).to receive(:is_ready?).and_return(true)
  end

  it 'includes the database_migrations recipe' do
    expect(chef_run).to include_recipe('registry::database_migrations')
  end
end
